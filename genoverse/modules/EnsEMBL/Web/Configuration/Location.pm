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

package EnsEMBL::Web::Configuration::Location;

use strict;

use previous qw(modify_tree get_configurable_components);

sub modify_tree {
  my $self = shift;
  my @view = grep $_, ( $self->get_node('View'), $self->get_node('Compara_Alignments/Image') );
  
  $_->set_data('genoverse', 1) for @view;
  
  $self->PREV::modify_tree;
}

sub get_configurable_components {
  my $self       = shift;
  my $node       = shift;
  my $components = $self->PREV::get_configurable_components($node, @_);

  map { $_->[0] eq 'ViewTop' && push @$_, 'genoverse' } @$components if $node && $node->get_data('genoverse');

  return $components;
}

1;
