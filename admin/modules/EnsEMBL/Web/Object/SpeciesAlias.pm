package EnsEMBL::Web::Object::SpeciesAlias;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('SpeciesAlias');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    species           => {
      'type'      => 'dropdown',
      'label'     => 'Species name',
      'required'  => 1,
    },
    alias             => {
      'type'      => 'string',
      'label'     => 'Alias',
      'required'  => 1,
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    species         => 'Species',
    alias           => 'Alias',
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'species alias',
    'plural'   => 'species aliases'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

1;
