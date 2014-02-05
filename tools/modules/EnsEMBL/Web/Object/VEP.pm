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

package EnsEMBL::Web::Object::VEP;

use strict;
use warnings;

use EnsEMBL::Web::TmpFile::Text;
use EnsEMBL::Web::TmpFile::VcfTabix;

use base qw(EnsEMBL::Web::Object::Tools);

sub ticket_type {
  ## Abstract method implementation
  return 'VEP';
}

sub result_files {
  ## Gets the result stats and ouput files
  my $self = shift;

  if (!$self->{'_results_files'}) {
    my $ticket      = $self->get_requested_ticket or return;
    my $job         = $ticket->job->[0] or return;
    my $job_config  = $job->hive_job_data->{'config'};
    my $job_dir     = $job->job_dir;

    $self->{'_results_files'} = {
      'output_file' => EnsEMBL::Web::TmpFile::VcfTabix->new('filename' => "$job_dir/$job_config->{'output_file'}"),
      'stats_file'  => EnsEMBL::Web::TmpFile::Text->new('filename' => "$job_dir/$job_config->{'stats_file'}")
    };
  }

  return $self->{'_results_files'};
}

1;
