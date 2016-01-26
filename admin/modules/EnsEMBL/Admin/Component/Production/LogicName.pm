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

package EnsEMBL::Admin::Component::Production::LogicName;

use strict;

use parent qw(EnsEMBL::ORM::Component::DbFrontend::List);

sub caption {
  return '';
}

sub content_tree {
  ## @overrides
  my $self    = shift;

  my $tree = $self->SUPER::content_tree;

  $_->inner_HTML('No analysis web data found in the database for the applied filter.') for @{$tree->get_nodes_by_flag($self->_FLAG_NO_CONTENT)};

  return $tree;
}

sub record_tree {
  ## @overrides
  my $record_div = shift->SUPER::record_tree(@_);

  $_->inner_HTML($_->inner_HTML ? 'Yes' : 'No')  for @{$record_div->get_nodes_by_flag('displayable')};
  !$_->inner_HTML and $_->inner_HTML('<i>null</i>') for @{$record_div->get_elements_by_tag_name('td')};

  return $record_div;
}

1;