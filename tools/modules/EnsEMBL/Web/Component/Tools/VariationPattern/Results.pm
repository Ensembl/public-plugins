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

package EnsEMBL::Web::Component::Tools::VariationPattern::Results;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools::VariationPattern);

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $job       = $object->get_requested_job({'with_all_results' => 1});
  my $current   = $hub->species_defs->ENSEMBL_VERSION;
  my $filename  = $job->dispatcher_data->{'output_file'};
  my $down_url  = $object->download_url;
  
  return '' unless $job;
    
  my $content   = file_get_contents(join('/', $job->job_dir, $filename), sub { s/\R/\r\n/r });

  return scalar(split('\n',$content)) > 1 ? qq{<p>Click on the button below to download the result file.</p><p><div class="component-tools tool_buttons"><a class="export" href="$down_url">Download results file</a></div></p>} : $self->_warning('No results', 'No results obtained.');
}

1;
