package EnsEMBL::Web::Object::AnalysisDesc;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('AnalysisDescription');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    logic_name        => {
      'type'      => 'string',
      'label'     => 'Logic Name'
    },
    display_label     => {
      'type'      => 'string',
      'label'     => 'Display Label'
    },
    description       => {
      'type'      => 'text',
      'label'     => 'Description'
    },
    db_version        => {
      'type'      => 'dropdown',
      'label'     => 'DB Version',
      'values'    => [{'value' => '1', 'caption' => 'Yes'}, {'value' => '0', 'caption' => 'No'}]
    },
    default_web_data  => {
      'type'      => 'radiolist',
      'label'     => 'Default Web data',
      'is_null'   => 'None'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    logic_name        => 'Logic Name',
    display_label     => 'Display Label',
    description       => 'Description',
    default_web_data  => 'Default Web data'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'analysis description',
    'plural'   => 'analysis descriptions'
  };
}

sub permit_delete {
  ## @overrides
  return 'delete';
}

1;