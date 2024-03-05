=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::JobDispatcher::BlatLocal;

### Dispatcher to run the BLAT jobs on local web machine

use strict;
use warnings;

use IO::Socket;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::JobDispatcher);

use constant {
  LOG_FILE    => 'blat.log',
  STATUS_FILE => 'blat.done'
};

sub dispatch_job {
  ## Abstract method implementation
  my ($self, $ticket_type, $job_data) = @_;

  my $blat_bin    = $job_data->{'blat_bin'};
  my $input_file  = sprintf '%s/%s', $job_data->{'work_dir'}, $job_data->{'sequence'}{'input_file'};
  my $output_file = sprintf '%s/%s', $job_data->{'work_dir'}, $job_data->{'output_file'};
  my $log_file    = sprintf '%s/%s', $job_data->{'work_dir'}, LOG_FILE;
  my $status_file = sprintf '%s/%s', $job_data->{'work_dir'}, STATUS_FILE;
  my ($host, $port, $nib_dir) = split ':', $job_data->{'source_file'}, 3;
  $nib_dir ||= '/';

  throw exception('WebException', "Input query sequence file ($input_file) missing for BLAT") unless -f $input_file;
  throw exception('WebException', "$blat_bin is either missing or not executable") unless -e $blat_bin && -X $blat_bin;
  throw exception('WebException', "Nib dir $nib_dir does not exists") unless -e $nib_dir && -d $nib_dir;
  throw exception('WebException', "Bad format for BLAT search DB: $job_data->{'source_file'}. Use host:port:nib_path format.") unless $host && $port;
  throw exception('WebException', "BLAT server unavailable $@") unless $self->_check_server($host, $port);

  system "( $blat_bin -out=blast -minScore=0 -minIdentity=0 $host $port $nib_dir $input_file $output_file 2>$log_file ; touch $status_file ) &";

  return $job_data->{'job_id'};
}

sub delete_jobs {}

sub update_jobs {
  ## Abstract method implementation
  my ($self, $jobs) = @_;

  foreach my $job (@$jobs) {

    my $job_data    = $job->dispatcher_data;
    my $output_file = sprintf '%s/%s', $job_data->{'work_dir'}, $job_data->{'output_file'};
    my $log_file    = sprintf '%s/%s', $job_data->{'work_dir'}, LOG_FILE;
    my $status_file = sprintf '%s/%s', $job_data->{'work_dir'}, STATUS_FILE;

    # if status file exists, it means process is finished
    if (-e $status_file) {

      if (-e $output_file) {

        # TODO - parse the file and add results to result row

        # job is done, set status accordingly
        $job->status('done');
        $job->dispatcher_status('done');

      } else {

        # job failed due to some reason, need user to look into it
        $job->status('awaiting_user_response');
        $job->dispatcher_status('failed');

        # save the error message from log file
        $job->job_message([{
          'display_message' => $self->default_error_message,
          'exception'       => {'exception' => -e $log_file ? join('', file_get_contents($log_file)) : 'Unknown error'},
          'fatal'           => 1
        }]);
      }
    } else {

      # job is still running, so no need to change 'status', only set the 'dispatcher_status' ('if' condition prevents an extra SQL query)
      $job->dispatcher_status('running') if $job->dispatcher_status ne 'running';
    }

    # update if anything is changed
    $job->save('changes_only' => 1);
  }
}

sub _check_server {
  ## @private
  my ($self, $host, $port) = @_;

  my $server = IO::Socket::INET->new(
    PeerAddr  => $host,
    PeerPort  => $port,
    Proto     => 'tcp',
    Type      => SOCK_STREAM,
    Timeout   => 10
  );

  $server->autoflush(1);

  return !!$server;
}

1;
