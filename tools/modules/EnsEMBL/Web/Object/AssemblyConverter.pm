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

use parent qw(EnsEMBL::Web::Object::Tools);

sub handle_download {
### Retrieves file contents and outputs direct to Apache
### request, so that the browser will download it instead
### of displaying it in the window.
### Uses Controller::Download, via url /Download/DataExport/
  my ($self, $r) = @_;
  my $hub = $self->hub;

  if (!$self->{'_results_files'}) {
    my $ticket      = $self->get_requested_ticket or return;
    my $job         = $ticket->job->[0] or return;
    my $job_config  = $job->dispatcher_data->{'config'};
    my $job_dir     = $job->job_dir;

    my $filename    = $job_config->{'output_file'};
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
