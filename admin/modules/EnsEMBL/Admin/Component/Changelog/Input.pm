package EnsEMBL::Admin::Component::Changelog::Input;

### Customised DbFrontend Input component

use strict;

use base qw(EnsEMBL::ORM::Component::DbFrontend::Input);

sub content_tree {
  ## @overrides
  my $self = shift;
  
  my $content = $self->SUPER::content_tree;
  
  foreach my $field (@{$content->get_nodes_by_flag('species')}) {
    my $select = $field->get_elements_by_tag_name('select');
    if (@$select) {
      $select->[0]->prepend_child($self->dom->create_element('option', {'value' => '0', 'inner_HTML' => 'All Species'}))->selected((scalar @{$select->[0]->selected_index}) ? 0 : 1);
    }
    else {
      $field->add_element({'type' => 'noedit', 'no_input' => 1, 'caption' => 'All Species'}) unless @{$field->elements};
    }
    last;
  }
  
  return $content;
}

1;