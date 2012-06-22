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
    biotype_group => {
      'type'      => 'dropdown',
      'label'     => 'Biotype Group',
    },
    attrib_type       => {
      'type'      => 'dropdown',
      'label'     => 'Attribute code (if the biotype is included in density feature calculations)',
      'is_null'   => 'None',
    },
    is_dumped         => {
      'type'      => 'dropdown',
      'label'     => 'Is this biotype dumped?',
      'values'    => [{'value' => '1', 'caption' => 'Yes'}, {'value' => '0', 'caption' => 'No'}]
    },
    description       => {
      'type'      => 'text',
      'label'     => 'Description',
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    name        => 'Name',
    object_type => 'Object Type',
    db_type     => 'Database Type'
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