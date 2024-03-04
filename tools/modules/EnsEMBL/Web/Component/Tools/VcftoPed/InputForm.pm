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

package EnsEMBL::Web::Component::Tools::VcftoPed::InputForm;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::VcftoPed
  EnsEMBL::Web::Component::Tools::ThousandGenomeInputForm
);

sub form_header_info {
  my $self  = shift;
  return $self->tool_header({'reset' => 'Clear form', 'cancel' => 'Close'}).'<p class="info">This tool parses a vcf file to create a linkage pedigree file (PED) and a marker information file, which together may be loaded into LD visualization tools such as Haploview.</p>';
}

sub get_cacheable_form_node {
  ## Overwriting parent ThousandGenomeInputForm by adding radio button for base format
  my $self    = shift;

  my $form      = $self->common_form;
  my $fieldset  = $form->fieldsets->[0];
  
  $fieldset->add_field({
    'type'          => 'string',
    'name'          => 'region_check',
    'value'         => '2500000',
    'field_class'   => 'hidden',
  });

  $fieldset->add_field({
    'type'          => 'radiolist',
    'name'          => 'base',
    'label'         => '<span class="ht _ht"><span class="_ht_tip hidden">Choose how to express the genotypes; either as bases (ATGC) or numbers (1234).</span>Base format</span>',
    'values'        => [{ 'value' => 'letters',  'caption' => 'Bases' }, { 'value' => 'numbers',  'caption' => 'Numbers', 'checked' => 'true' }],
  });
  
  $fieldset->add_field({
    'type'          => 'checkbox',
    'name'          => 'biallelic',
    'label'         => '<span class="ht _ht"><span class="_ht_tip hidden">Exclude sites with more than two alleles from output</span>Biallelic only</span>',
    'value'         => 1,
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

#Overwriting parent one to remove ALL in the population list
sub get_populations {
  my $self    = shift;

  my $pops = $self->SUPER::get_populations(@_);  
  splice @$pops, 0,1; # ALL is the first element in the array
  
  return $pops; 

}

1;
