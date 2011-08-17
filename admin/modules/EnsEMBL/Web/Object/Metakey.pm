package EnsEMBL::Web::Object::Metakey;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('MetaKey');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    name              => {
      'type'      => 'string',
      'label'     => 'Name'
    },
    is_optional       => {
      'type'      => 'dropdown',
      'label'     => 'Is this meta key optional?',
      'values'    => [{'value' => '0', 'caption' => 'No'}, {'value' => '1', 'caption' => 'Yes'}]
    },
    db_type           => {
      'type'      => 'dropdown',
      'label'     => 'Database Type',
    },
    species           => {
      'type'      => 'dropdown',
      'label'     => 'Related Species',
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
    db_type     => 'Database Type',
    species     => 'Related Species'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'meta key',
    'plural'   => 'meta keys'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

1;