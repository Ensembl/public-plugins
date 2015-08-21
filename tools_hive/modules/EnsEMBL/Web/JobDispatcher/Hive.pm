=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::JobDispatcher::Hive;

use strict;
use warnings;

use JSON qw(from_json);

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::AnalysisJob;

use EnsEMBL::Web::Exceptions;

use parent qw(EnsEMBL::Web::JobDispatcher);

sub dispatch_job {
  ## Abstract method implementation
  my ($self, $logic_name, $job_data) = @_;

  my $hive_job_id;

  try {

    my $hive_dba    = $self->hive_dba;
    my $job_adaptor = $self->job_adaptor;

    $self->{'_analysis'}{$logic_name} ||= $hive_dba->get_AnalysisAdaptor->fetch_by_logic_name_or_url($logic_name);

    # Submit job to hive db
    my $hive_job = Bio::EnsEMBL::Hive::AnalysisJob->new(
      'analysis'  => $self->{'_analysis'}{$logic_name},
      'input_id'  => $job_data
    );

    ($hive_job_id) = @{ $job_adaptor->store_jobs_and_adjust_counters( [ $hive_job ] ) };

  } catch {

    # throw HiveError if anything goes wrong while submitting the job to the hive db
    $_->type('HiveError');
    throw $_;
  };

  return $hive_job_id;
}

sub delete_jobs {
  ## Abstract method implementation
  my ($self, $logic_name, $job_ids) = @_;
  my $hive_dba = $self->hive_dba;

#  $self->job_adaptor->remove_all(sprintf '`job_id` in (%s)', join(',', @$job_ids));
#  $hive_dba->get_Queen->safe_synchronize_AnalysisStats($hive_dba->get_AnalysisAdaptor->fetch_by_logic_name_or_url($logic_name)->stats);
}

sub update_jobs {
  ## Abstract method implementation
  my ($self, $jobs) = @_;

  foreach my $job (@$jobs) {

    my $hive_job = $self->job_adaptor->fetch_by_dbID($job->dispatcher_reference);

    if ($hive_job) {
      my $hive_job_status = $hive_job->status;

      if ($hive_job_status eq 'DONE') {

        # job is done, no more actions required
        $job->status('done');
        $job->dispatcher_status('done');
        $self->sync_log_messages($job, $hive_job); # sync any warnings

      } elsif ($hive_job_status =~ /^(FAILED|PASSED_ON)$/) {

        # job failed due to some reason, need user to look into it
        $job->status('awaiting_user_response');
        $job->dispatcher_status('failed');
        $self->sync_log_messages($job, $hive_job); # sync error message and any warnings

      } elsif ($hive_job_status =~ /^(SEMAPHORED|CLAIMED|COMPILATION)$/) {

        # job is just submitted to a queue
        $job->dispatcher_status('submitted') if $job->dispatcher_status ne 'submitted';

      } elsif ($hive_job_status =~ /^(PRE_CLEANUP|FETCH_INPUT|RUN|WRITE_OUTPUT|POST_CLEANUP)$/) {

        # job is still running, but keep an eye in it, so no need to change 'status', only set the 'dispatcher_status' ('if' condition prevents an extra SQL query)
        $job->dispatcher_status('running') if $job->dispatcher_status ne 'running';

      } # for READY status, no need to change status or dispatcher_status

    } else {

      # this will only get executed if the job got removed from the hive db's job table somehow (very unlikely though)
      $job->status('awaiting_user_response');
      $job->dispatcher_status('deleted');
      $job->job_message([{'display_message' => 'Submitted job has been deleted from the queue.'}]);
    }

    # update if anything is changed
    $job->save('changes_only' => 1);
  }
}

sub hive_dba {
  ## @private
  ## Gets new or cached hive db adaptor
  ## @return Bio::EnsEMBL::Hive::DBSQL::DBAdaptor object
  my $self = shift;

  unless ($self->{'_hive_dba'}) {
    my $sd      = $self->hub->species_defs;
    my $hivedb  = $sd->multidb->{'DATABASE_WEB_HIVE'};

    # if SiteDefs say db is not available, no need to check it further
    throw exception('HiveError', 'ENSEMBL_HIVE_DB is not available') if $sd->ENSEMBL_HIVE_DB_NOT_AVAILABLE;

    $ENV{'EHIVE_ROOT_DIR'} ||= $sd->ENSEMBL_SERVERROOT.'/ensembl-hive/'; # used in hive API

    $self->{'_hive_dba'} = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new('-url' => sprintf('mysql://%s:%s@%s:%s/%s',
      $hivedb->{'USER'} || $sd->DATABASE_WRITE_USER,
      $hivedb->{'PASS'} || $sd->DATABASE_WRITE_PASS,
      $hivedb->{'HOST'},
      $hivedb->{'PORT'},
      $hivedb->{'NAME'},
    ));
  }
  return $self->{'_hive_dba'};
}

sub job_adaptor {
  ## @private
  ## Gets new or cached hive job adaptor
  ## @return AnalysisJobAdaptor object
  my $self = shift;

  return $self->{'_job_adaptor'} ||= $self->hive_dba->get_AnalysisJobAdaptor;
}

sub sync_log_messages {
  ## @private
  my ($self, $job, $hive_job) = @_;

  my @messages;

  for (@{$self->hive_dba->get_LogMessageAdaptor->fetch_all_by_job_id($hive_job->dbID)}) {

    next unless $_->{'msg'}; # ignore if msg is an empty string

    my $parsed;

    if ($_->{'msg'} =~ /^{.*}$/) {
      try {
        $parsed = from_json($_->{'msg'});
      } catch {};
    }

    next if !$_->{'is_error'} && !$parsed; # warnings that are not in JSON format should be ignored

    push(@messages, $parsed
      ? {
        'display_message'   => delete $parsed->{'data'}{'display_message'} // $self->default_error_message,
        'fatal'             => delete $parsed->{'data'}{'fatal'} // 1,
        'data'              => delete $parsed->{'data'},
        'exception'         => $_->{'is_error'} ? $parsed : undef,
      }
      : {
        'display_message'   => $self->default_error_message,
        'exception'         => {'exception' => $_->{'msg'} || 'Unknown error'},
        'fatal'             => 1
      }
    );
  }

  $job->job_message(\@messages) if @messages;
}

sub DESTROY {
  ## Close the hive db connection when exiting
  my $self = shift;
  $self->{'_hive_dba'}->dbc->disconnect_when_inactive(1) if $self->{'_hive_dba'} && $self->{'_hive_dba'}->dbc;
}

1;
