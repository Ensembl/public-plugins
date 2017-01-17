=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Component::Changelog::Display;

use strict;
use warnings;

use parent qw(EnsEMBL::ORM::Component::DbFrontend::Display);

sub record_tree {
  ## @overrides
  ## Adds a link 'Copy to current release' in case release on changelog is not same as current release
  my ($self, $record) = @_;

  my $hub         = $self->hub;
  my $object      = $self->object;
  my $record_div  = $self->SUPER::record_tree($record);
  my $current_rel = $object->current_release;
  
  if ($record->release_id ne $current_rel) {
    if (my $button_div = $record_div->get_nodes_by_flag($self->_FLAG_RECORD_BUTTONS)->[0]) {
      my $button = $button_div->append_HTML(sprintf('<a href="%s">Copy to current release (%s)</a>',
        $hub->url({'action' => 'Duplicate', 'id' => $record->get_primary_key_value, 'release' => $current_rel}),
        $current_rel)
      );
    }
  }

  return $record_div;
}

1;