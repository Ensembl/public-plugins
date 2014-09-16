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

package EnsEMBL::Web::Object::AssemblyConverter;

use strict;
use warnings;

use EnsEMBL::Web::TmpFile::ToolsOutput;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::Object::Tools);

sub get_edit_jobs_data {
  ## Abstract method implementation
  my $self        = shift;
  my $hub         = $self->hub;
  my $ticket      = $self->get_requested_ticket   or return [];
  my $job         = shift @{ $ticket->job || [] } or return [];
  my $job_data    = $job->job_data->raw;
  my $input_file  = sprintf '%s/%s', $job->job_dir, $job_data->{'input_file'};
  warn ">>> INPUT $input_file";
  my $format      = $job_data->{'format'};

  if (-T $input_file && $input_file !~ /\.gz$/ && $input_file !~ /\.zip$/) { # TODO - check if the file is binary!
    if (-s $input_file <= 1024) {
      $job_data->{"text_$format"} = join('', file_get_contents($input_file));
    } else {
      my $url_param   = $self->create_url_param({'ticket_name' => $ticket->ticket_name});
      $job_data->{'input_file_type'}  = 'text';
      $job_data->{'input_file_url'}   = sprintf('/Download/AssemblyConverter?tl=%s;input=1', $url_param);
    }
  } else {
    $job_data->{'input_file_type'} = 'binary';
  }

  return [ $job_data ];
}

sub handle_download {
### Retrieves file contents and outputs direct to Apache
### request, so that the browser will download it instead
### of displaying it in the window.
### Uses Controller::Download, via url /Download/AssemblyConverter/
  my ($self, $r) = @_;
  my $hub = $self->hub;

  if (!$self->{'_results_files'}) {
    my $ticket      = $self->get_requested_ticket or return;
    my $job         = $ticket->job->[0] or return;
    my $job_config  = $job->dispatcher_data->{'config'};
    my $job_dir     = $job->job_dir;

    my $filename    = $hub->param('input') ? $job_config->{'input_file'} : $job_config->{'output_file'};

    ## Horrible hack for CrossMap stupidity
    if (!$hub->param('input') && ($job_config->{'format'} eq 'wig')) {
      $filename .= '.bgr';
    }
    my $path        = $job_dir.'/'.$filename;

    ## Strip double dots to prevent downloading of files outside tmp directory
    $path =~ s/\.\.//g;
    ## Remove any remaining illegal characters
    $path =~ s/[^\w|-|\.|\/]//g;

    my $tmpfile = EnsEMBL::Web::TmpFile::ToolsOutput->new('filename' => $path); 

    if ($tmpfile->exists) {
      my $content = $tmpfile->content;

      $r->headers_out->add('Content-Type'         => 'text/plain');
      $r->headers_out->add('Content-Length'       => length $content);
      $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s', $filename);

      print $content;
    }
    else { warn ">>> PATH NOT RECOGNISED: $path"; }
  }
}

1;
