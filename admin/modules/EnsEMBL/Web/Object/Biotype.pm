package EnsEMBL::Web::Object::Biotype;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('Biotype');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    name              => {
      'type'      => 'string',
      'label'     => 'Name'
    },
    object_type       => {
      'type'      => 'dropdown',
      'label'     => 'Object Type',
    },
    db_type           => {
      'type'      => 'dropdown',
      'label'     => 'Database Type',
    },
    is_dumped         => {
      'type'      => 'dropdown',
      'label'     => 'Is this biotype dumped?',
      'values'    => [{'value' => '1', 'caption' => 'Yes'}, {'value' => '0', 'caption' => 'No'}]
    },
    description       => {
      'type'      => 'text',
      'label'     => 'Description',
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
    name        => 'Name',
    object_type => 'Object Type',
    db_type     => 'DB Type'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'biotype',
    'plural'   => 'biotypes'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

1;