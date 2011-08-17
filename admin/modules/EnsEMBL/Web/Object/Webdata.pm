package EnsEMBL::Web::Object::Webdata;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('WebData');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    data  => {
      'type'  => 'html',
      'label' => 'Web Data',
      'value' => '{}'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    data  => 'Web Data',
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'web data',
    'plural'   => 'web data',
  };
}

sub record_select_style {
  ## @overrides
  return 'radio';
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

1;