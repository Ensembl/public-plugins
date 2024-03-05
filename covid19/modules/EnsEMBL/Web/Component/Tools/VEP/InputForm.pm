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

package EnsEMBL::Web::Component::Tools::VEP::InputForm;

use strict;
use warnings;
use previous qw(get_cacheable_form_node);

sub get_cacheable_form_node {
  my $self      = shift;
  my $form      = $self->PREV::get_cacheable_form_node(@_);
  $form->get_elements_by_class_name('quick-vep-button')->[0]->remove();
  $form->get_elements_by_class_name('add_species_link')->[0]->remove();
  return $form;
}

1;

