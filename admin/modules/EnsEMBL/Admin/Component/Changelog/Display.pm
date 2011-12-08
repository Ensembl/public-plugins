package EnsEMBL::Admin::Component::Changelog::Display;

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend::Display);

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