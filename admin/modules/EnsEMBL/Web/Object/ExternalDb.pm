package EnsEMBL::Web::Object::ExternalDb;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('ExternalDb');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    external_db_id      => {
      'type'      => 'noedit',
      'label'     => 'External DB ID',
      'value'     => '<i>to be assigned</i>',
      'is_html'   => 1
    },
    db_name             => {
      'type'      => 'string',
      'label'     => 'Name',
      'required'  => 1
    },
    db_release          => {
      'type'      => 'string',
      'label'     => 'Release'
    },
    status              => {
      'type'      => 'dropdown',
      'label'     => 'Status',
      'required'  => 1
    },
    db_display_name     => {
      'type'      => 'string',
      'label'     => 'Display name'
    },
    priority            => {
      'type'      => 'string',
      'label'     => 'Priority'
    },
    type                => {
      'type'      => 'dropdown',
      'label'     => 'Type'
    },
    secondary_db_name   => {
      'type'      => 'string',
      'label'     => 'Secondary db name'
    },
    secondary_db_table  => {
      'type'      => 'string',
      'label'     => 'Secondary db table'
    },
    description         => {
      'type'      => 'text',
      'label'     => 'Description'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    external_db_id  => {'title' => 'Ext. DB ID', 'editable' => 0},
    db_name         => 'Name',
    db_release      => 'Release',
    status          => 'Status'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'external db',
    'plural'   => 'external dbs'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}
1;
