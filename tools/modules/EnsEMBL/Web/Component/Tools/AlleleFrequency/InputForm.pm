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

package EnsEMBL::Web::Component::Tools::AlleleFrequency::InputForm;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::AlleleFrequency
  EnsEMBL::Web::Component::Tools::ThousandGenomeInputForm
);

sub form_header_info {
  my $self  = shift;
  return $self->tool_header({'reset' => 'Clear form', 'cancel' => 'Close'}).'<p class="info">This tool calculates population-wide allele frequencies for variations within a defined chromosomal region.</p>';
}

sub get_cacheable_form_node {
  ## Overwriting parent ThousandGenomeInputForm by adding region_check hidden input
  my $self    = shift;

  my $form      = $self->common_form;
  my $fieldset  = $form->fieldsets->[0];

  $fieldset->add_field({
    'type'          => 'string',
    'name'          => 'region_check',    
    'value'        => '2500000',
    'field_class'  => 'hidden',
  });
  
  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## use generic js for 1000genome form
  return 'ThousandGenome';
}

1;
