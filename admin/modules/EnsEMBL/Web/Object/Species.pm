package EnsEMBL::Web::Object::Species;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('Species');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    web_name          => {
      'type'      => 'string',
      'label'     => 'Name on website',
      'required'  => 1,
    },
    db_name           => {
      'type'      => 'string',
      'label'     => 'Name in database',
      'required'  => 1,
    },
    common_name       => {
      'type'      => 'string',
      'label'     => 'Common Name',
      'required'  => 1,
    },
    created_by_user   => {
      'type'      => 'noedit',
      'label'     => 'Created by'
    },
    created_at        => {
      'type'      => 'noedit',
      'label'     => 'Created at'
    },
    modified_by_user  => {
      'type'      => 'noedit',
      'label'     => 'Modified by'
    },
    modified_at       => {
      'type'      => 'noedit',
      'label'     => 'Modified at'
    },
  ];
}

sub show_columns {
  ## @overrides
  return [
    web_name    => 'Web name',
    db_name     => 'Database name',
    common_name => 'Common name'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'species',
    'plural'   => 'species'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

1;
