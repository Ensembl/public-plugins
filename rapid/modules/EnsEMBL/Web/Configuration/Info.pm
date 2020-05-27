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

package EnsEMBL::Web::Configuration::Info;

use strict;

sub modify_tree {
  my $self   = shift;
  $self->delete_node('Index');
  $self->delete_node('Annotation');
  $self->delete_node('LocationGallery');
  $self->delete_node('GeneGallery');
  $self->delete_node('VariationGallery');
  ## Use modified annotation page instead of regular home page
  $self->create_node('Index', '', [qw(homepage EnsEMBL::Web::Component::Info::SpeciesBlurb)], {});
}

1;
