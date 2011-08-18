package EnsEMBL::Web::Object::AttribType;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('AttribType');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    name        => {
      'type'      => 'string',
      'label'     => 'Name',
      'required'  => 1
    },
    code        => {
      'type'      => 'string',
      'label'     => 'Code',
      'required'  => 1
    },
    description => {
      'type'      => 'text',
      'label'     => 'Description'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    name        => 'Name',
    code        => 'Code',
    description => 'Description'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'attribute type',
    'plural'   => 'attribute types'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}
1;