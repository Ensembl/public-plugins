package EnsEMBL::Web::Object::Production;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

sub fetch_for_logicname {
  ## Rose objects for LogicName page (non-DbFrontend page)
  my $self = shift;
  $self->rose_objects($self->manager_class->fetch_by_page($self->pagination, $self->get_page_number, {
    'with_objects'  => ['analysis_web_data', 'analysis_web_data.species', 'analysis_web_data.web_data'],
    'sort_by'       => 'display_label'
  }));
}

sub default_action {
  ## @overrides
  return 'LogicName';
}

sub manager_class {
  ## @overrides
  return shift->rose_manager('AnalysisDescription');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    logic_name      => {
      'type'      => 'string',
      'label'     => 'Logic Name',
      'required'  => 1,
    },
    display_label   => {
      'type'      => 'string',
      'label'     => 'Display Label',
      'required'  => 1,
    },
    description     => {
      'type'      => 'html',
      'label'     => 'Description',
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
    logic_name    => 'Logic Name',
    display_label => 'Display Label',
    description   => 'Description',
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'analysis description',
    'plural'   => 'analysis descriptions',
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

sub pagination {
  ## @overrides
  return 50;
}

1;