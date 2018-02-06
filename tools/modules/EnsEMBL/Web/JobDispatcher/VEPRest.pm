=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::JobDispatcher::VEPRest;

use strict;
use warnings;

use JSON qw(to_json);
use LWP::UserAgent;

use EnsEMBL::Web::VEPConstants qw(REST_DISPATCHER_SERVER_ENDPOINT);
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents file_put_contents);

use parent qw(EnsEMBL::Web::JobDispatcher);

sub dispatch_job {
  ## Abstract method implementation
  my ($self, $ticket_type, $job_data) = @_;

  my $species     = $job_data->{'config'}{'species'};
  my $endpoint    = REST_DISPATCHER_SERVER_ENDPOINT =~ s/\:species/$species/r;
  my $input_file  = join '/', $job_data->{'work_dir'}, $job_data->{'config'}{'input_file'};
  my $output_file = join '/', $job_data->{'work_dir'}, $job_data->{'config'}{'output_file'};
  my $output_json = $output_file =~ s/\.[^\.]+$/.json/r;
  my $status_file = "$output_json.status";
  my @variants    = file_get_contents($input_file, sub { s/\R//r });

  my $response    = $self->_post($endpoint, to_json({'variants' => \@variants}));

  file_put_contents("$output_json.status", $response->status_line);
  file_put_contents($output_json, $response->content) if $response->is_success;

  # this will get saved in dispatcher data column
  $job_data->{'status_file'} = $status_file;
  $job_data->{'output_json'} = $output_json;

  return $job_data->{'job_id'};
}

sub delete_jobs {
  ## Nothing needs to be done here
}

sub update_jobs {
  ## Abstract method implementation
  my ($self, $jobs) = @_;

  for (@$jobs) {
    my $job_data  = $_->dispatcher_data;
    my ($status)  = $job_data->{'status_file'} && -e $job_data->{'status_file'} ? file_get_contents($job_data->{'status_file'}) : ('Job does not exist');

    if ($status =~ /^200/) {

      # job successful
      $_->dispatcher_status('done');
      $_->status('done');

    } else {

      # job failed
      $_->dispatcher_status('failed');
      $_->status('awaiting_user_response');
      $_->job_message([{
        'display_message'   => $self->default_error_message,
        'exception'         => {'exception' => $status},
        'fatal'             => 1
      }]);
    }
  }
}

sub _post {
  my ($self, $url, $message) = @_;

  my $ua = LWP::UserAgent->new;
     $ua->proxy([qw(http https)], $_) for $self->web_proxy || ();

  my $request = HTTP::Request->new('POST', $url);

  $request->header('Content-type'  => 'application/json');
  $request->header('Cache-control' => 'no-cache');
  $request->header('Pragma'        => 'no-cache');
  $request->content($message);

  return $ua->request($request);
}

1;
