=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use parent qw(EnsEMBL::Web::JobDispatcher);

sub dispatch_job {
  ## Abstract method implementation
  my ($self, $ticket_type, $job_data) = @_;

  my $hive_dba    = $self->hive_dba;
  my $job_adaptor = $self->job_adaptor;

  $self->{'_analysis_id'}{$ticket_type} ||= $hive_dba->get_AnalysisAdaptor->fetch_by_logic_name_or_url($ticket_type)->dbID;

  # Submit job to hive db
  my $hive_job = Bio::EnsEMBL::Hive::AnalysisJob->new(
		-analysis_id  => $self->{'_analysis_id'}{$ticket_type},
		-input_id	    => $job_data,
  );

  my ($hive_job_id) = @{ $job_adaptor->store_jobs_and_adjust_counters( [ $hive_job ] ) };

  return $hive_job_id;
}

sub delete_jobs {
  ## Abstract method implementation
  my $self        = shift;
  my $ticket_type = shift;
  my $hive_dba    = $self->hive_dba;

  $self->job_adaptor->remove_all(sprintf '`job_id` in (%s)', join(',', @_));
  $hive_dba->get_Queen->safe_synchronize_AnalysisStats($hive_dba->get_AnalysisAdaptor->fetch_by_logic_name_or_url($ticket_type)->stats);
}

sub update_jobs {
  ## Abstract method implementation
  my ($self, $jobs) = @_;

  foreach my $job (@$jobs) {

    my $hive_job_id = $job->dispatcher_reference;
    my $hive_dba    = $self->hive_dba;
    my $hive_job    = $self->job_adaptor->fetch_by_dbID($hive_job_id);

    if ($hive_job) {
      my $hive_job_status = $hive_job->status;

      if ($hive_job_status eq 'DONE') {

        # job is done, no more actions required
        $job->status('done');
        $job->dispatcher_status('done');

      } elsif ($hive_job_status =~ /^(FAILED|PASSED_ON)$/) {

        # job failed due to some reason, need user to look into it
        $job->status('awaiting_user_response');
        $job->dispatcher_status('failed');

        # Get the log message and save it in the message column
        my ($message) = map {$_->{'is_error'} && $_->{'msg'} || ()} @{$hive_dba->get_LogMessageAdaptor->fetch_all_by_job_id($hive_job_id)}; # ignore if msg is an empty string
        if ($message && $message =~ /^{.*}$/) { # possibly json
          try {
            $message = from_json($message);
          } catch {};
        }

        $job->job_message([ref $message
          ? {
            'display_message'   => delete $message->{'data'}{'display_message'} // $self->default_error_message,
            'fatal'             => delete $message->{'data'}{'fatal'} // 1,
            'data'              => delete $message->{'data'},
            'exception'         => $message,
          }
          : {
            'display_message'   => $self->default_error_message,
            'exception'         => {'exception' => $message || 'Unknown error'},
            'fatal'             => 1
          }
        ]);

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

    $ENV{'EHIVE_ROOT_DIR'} ||= $sd->ENSEMBL_SERVERROOT.'/ensembl-hive/'; # use in hive API

    $self->{'_hive_dba'} = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new(
      -user   => $hivedb->{'USER'} || $sd->DATABASE_WRITE_USER,
      -pass   => $hivedb->{'PASS'} || $sd->DATABASE_WRITE_PASS,
      -host   => $hivedb->{'HOST'},
      -port   => $hivedb->{'PORT'},
      -dbname => $hivedb->{'NAME'},
    );
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

1;
