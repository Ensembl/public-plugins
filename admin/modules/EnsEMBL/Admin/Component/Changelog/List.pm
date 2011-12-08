package EnsEMBL::Admin::Component::Changelog::List;

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend::List);

sub content_tree {
  ## @overrides
  ## Disables Ajaxy interface if list is displayed with a 'pull' param - ie. user wants to copy a declaration to current release
  my $self    = shift;
  my $content = $self->SUPER::content_tree(@_);
  if ($self->hub->param('pull') && (my $table = $content->get_elements_by_class_name($self->_JS_CLASS_LIST_TABLE)->[0])) {
    $table->remove_attribute('class', $self->_JS_CLASS_LIST_TABLE);
  }
  return $content;
}

sub record_tree {
  ## @overrides
  ## Adds a link 'Copy to current release' in case 'pull' param is found
  my ($self, $record, $css_class, $header_only) = @_;

  my $hub         = $self->hub;
  my $object      = $self->object;
  my $record_div  = $self->SUPER::record_tree($record, $css_class, $header_only);
  
  if ($hub->param('pull')) {
    my $first_cell = $record_div->first_child;
    if ($header_only) {
      $first_cell->set_attribute('style', 'width: 165px');
    }
    else {
      $first_cell->remove_attribute('class');
      $first_cell->inner_HTML(sprintf('<a href="%s">Copy&nbsp;to&nbsp;current&nbsp;release&nbsp;(%s)</a>',
        $hub->url({'action' => 'Duplicate', 'release' => $_, 'id' => $record->get_primary_key_value}),
      $_)) for $object->current_release;
    }
  }

  return $record_div;
}

1;