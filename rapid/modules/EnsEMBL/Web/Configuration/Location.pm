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

package EnsEMBL::Web::Configuration::Location;

use strict;
use previous qw(modify_tree);


sub modify_tree {
  my $self   = shift;
  $self->PREV::modify_tree(@_);

  $self->delete_node('Compara');
  $self->delete_node('Variation');
  $self->delete_node('LD');
  $self->delete_node('Marker');

  

}

1;
