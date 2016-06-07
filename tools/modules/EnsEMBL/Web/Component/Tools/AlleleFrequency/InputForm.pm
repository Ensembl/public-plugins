=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::AlleleFrequency::InputForm;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::AlleleFrequency
  EnsEMBL::Web::Component::Tools::ThousandGenomeInputForm
);

sub form_header_info {
  my $self  = shift;
  return $self->info_panel('info','This tool calculates population-wide allele frequency for sites within the chromosomal region defined from a VCF file and populations defined in a sample panel file. When no population is specified, allele frequencies will be calcuated for all populations in the VCF files. The results are written to a file. The total allele count, alternate allele count for the population is also included in the output file.');
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self    = shift;
  
  return $self->common_form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## use generic js for 1000genome form
  return 'ThousandGenomeForm';
}

1;
