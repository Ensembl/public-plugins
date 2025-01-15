=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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
use EnsEMBL::Web::Tools::FailOver::HiveDB;

use parent qw(EnsEMBL::Web::JobDispatcher);

sub dispatch_job {
  ## Abstract method implementation
  my ($self, $logic_name, $job_data) = @_;

  my $hive_job_id;

  try {

    my $hive_dba    = $self->_hive_dba;
    my $job_adaptor = $self->_job_adaptor;

    $self->{'_analysis'}{$logic_name} ||= $hive_dba->get_AnalysisAdaptor->fetch_by_logic_name($logic_name);

    # Submit job to hive db
    my $hive_job = Bio::EnsEMBL::Hive::AnalysisJob->new(
      'analysis'  => $self->{'_analysis'}{$logic_name},
      'input_id'  => { %$job_data, %{$self->_extra_global_params} }
    );

    ($hive_job_id) = @{ $job_adaptor->store_jobs_and_adjust_counters( [ $hive_job ] ) };

  } catch {

    # throw HiveError if anything goes wrong while submitting the job to the hive db
    $_->type('HiveError');
    throw $_;
  };

  return $self->_get_dispatcher_reference($hive_job_id);
}

sub delete_jobs {
  ## Abstract method implementation
  my ($self, $logic_name, $dispatcher_refs) = @_;

#   my $hive_dba      = $self->_hive_dba;
#   my @hive_job_ids  = map { $self->_get_hive_job_id($_) || () } @$dispatcher_refs;

#   if (@hive_job_ids) {
#     $self->_job_adaptor->remove_all(sprintf '`job_id` in (%s)', join(',', @hive_job_ids));
#     $hive_dba->get_Queen->safe_synchronize_AnalysisStats($hive_dba->get_AnalysisAdaptor->fetch_by_logic_name($logic_name)->stats);
#   }
}

sub update_jobs {
  ## Abstract method implementation
  my ($self, $jobs) = @_;

  my $hive_dba;

  try {
    $hive_dba = $self->_hive_dba;
  } catch {};

  # don't do anything if hive db there's a problem connecting hive db
  return unless $hive_dba;

  foreach my $job (@$jobs) {

    my $hive_job_id = $self->_get_hive_job_id($job->dispatcher_reference);

    if ($hive_job_id) {
      my $hive_job = $self->_job_adaptor->fetch_by_dbID($hive_job_id);

      if ($hive_job) {
        my $hive_job_status = $hive_job->status;

        if ($hive_job_status eq 'DONE') {

          # job is done, no more actions required
          $job->status('done');
          $job->dispatcher_status('done');
          $self->_sync_log_messages($job, $hive_job); # sync any warnings

        } elsif ($hive_job_status =~ /^(FAILED|PASSED_ON)$/) {

          # job failed due to some reason, need user to look into it
          $job->status('awaiting_user_response');
          $job->dispatcher_status('failed');
          $self->_sync_log_messages($job, $hive_job); # sync error message and any warnings

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

    } else {

      # if we couldn't retrieve hive_job_id form dispatcher_reference, it means the job was submitted to a different dispatcher (possibly another hive db)
      $job->dispatcher_status('no_details') if $job->dispatcher_status ne 'no_details';
    }

    # update if anything is changed
    $job->save('changes_only' => 1);
  }
}

sub _hive_dba {
  ## @private
  ## Gets new or cached hive db adaptor
  ## @return Bio::EnsEMBL::Hive::DBSQL::DBAdaptor object
  my $self = shift;

  unless ($self->{'_hive_dba'}) {

    # if hive db is not available, throw exception
    throw exception('HiveError', 'ENSEMBL_HIVE_DB is not available') unless EnsEMBL::Web::Tools::FailOver::HiveDB->new($self->hub)->get_cached;

    my $sd      = $self->hub->species_defs;
    my $hivedb  = $sd->hive_db;

    $self->{'_hive_dba'} = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new('-url' => sprintf('mysql://%s:%s@%s:%s/%s',
      $hivedb->{'username'},
      $hivedb->{'password'},
      $hivedb->{'host'},
      $hivedb->{'port'},
      $hivedb->{'database'},
    ));
  }
  return $self->{'_hive_dba'};
}

sub _job_adaptor {
  ## @private
  ## Gets new or cached hive job adaptor
  ## @return AnalysisJobAdaptor object
  my $self = shift;

  return $self->{'_job_adaptor'} ||= $self->_hive_dba->get_AnalysisJobAdaptor;
}

sub _sync_log_messages {
  ## @private
  my ($self, $job, $hive_job) = @_;

  my @messages;

  for (@{$self->_hive_dba->get_LogMessageAdaptor->fetch_all_by_job_id($hive_job->dbID)}) {

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

sub _get_hive_job_id {
  ## @private
  ## Gets hive_job_id from dispatcher_reference
  ## @return Hive id (int), or undef if dispatcher ref prefix doesn't match
  my ($self, $dispatcher_ref) = @_;

  my $prefix = $self->_dispatcher_reference_prefix;

  if ($dispatcher_ref && $dispatcher_ref =~ /^\Q$prefix\E([0-9]+)$/) {
    return $1;
  }
}

sub _get_dispatcher_reference {
  ## @private
  ## Creates a dispatcher reference string from hive job id
  ## @param Hive job id (job_id column of job table in hive)
  ## @return Dispatcher reference string containing info about the hive db as a prefix to the hive job id (or undef if no job id provided)
  my ($self, $hive_job_id) = @_;

  return $hive_job_id ? $self->_dispatcher_reference_prefix.$hive_job_id : undef;
}

sub _dispatcher_reference_prefix {
  ## @private
  ## Prefix to be added to dispatcher_reference to provide hive db info
  my $self    = shift;
  my $hivedb  = $self->hub->species_defs->hive_db;

  return sprintf 'HIVE:%s:%s:%s:', $hivedb->{'host'}, $hivedb->{'port'}, $hivedb->{'database'};
}

sub _extra_global_params {
  ## @private
  ## Returns extra global params that need to be provided to all jobs
  my $self  = shift;
  my $db    = $self->hub->species_defs->tools_db;

  return {
    "ticket_db" => {
      "-dbname" => $db->{'database'},
      "-host"   => $db->{'host'},
      "-pass"   => $db->{'password'},
      "-port"   => $db->{'port'},
      "-user"   => $db->{'username'}
    }
  };
}

sub DESTROY {
  ## Close the hive db connection when exiting
  my $self = shift;
  $self->{'_hive_dba'}->dbc->disconnect_when_inactive(1) if $self->{'_hive_dba'} && $self->{'_hive_dba'}->dbc;
}

1;
