package EnsEMBL::Web::Object::Production;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

sub fetch_for_logicname {
  my $self  = shift;
  my $hub   = $self->hub;
  my $group = $hub->param('gp');
  
  if (exists { map {$_ => 1} qw(web_data_id analysis_description_id species_id db_type) }->{$group}) {
    $self->rose_objects($self->manager_class->get_objects(
      'with_objects'  => ['analysis_description', 'species', 'web_data'],
      'sort_by'       => 'analysis_description.logic_name',
      'query'         => [$group, $hub->param('id')],
    ));
  }
}

sub fetch_for_analysiswebdata {
  my $self = shift;
  $self->rose_objects($self->manager_class->get_objects(
    'with_objects'  => ['analysis_description', 'species', 'web_data'],
    'sort_by'       => 'analysis_description.display_label'
  ));
}

sub default_action {
  ## @overrides
  return 'AnalysisWebData';
}

sub manager_class {
  ## @overrides
  return shift->rose_manager('AnalysisWebData');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    analysis_description => {
      'type'      => 'dropdown',
      'label'     => 'Logic Name',
      'required'  => 1,
    },
    species           => {
      'type'      => 'dropdown',
      'label'     => 'Species',
    },
    db_type           => {
      'type'      => 'dropdown',
      'label'     => 'Database type',
    },
    web_data          => {
      'type'      => 'radiolist',
      'label'     => 'Web Data',
    },
    displayable       => {
      'type'      => 'dropdown',
      'label'     => 'Displayable',
      'values'    => [{'value' => '1', 'caption' => 'Yes'}, {'value' => '0', 'caption' => 'No'}]
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
    analysis_description  => 'Logic Name',
    species               => 'Species',
    db_type               => 'Database Type',
    web_data              => {'title' => 'Web Data', 'width' => qq(50%)},
    displayable           => 'Displayable'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'analysis to web data link',
    'plural'   => 'analysis to web data links',
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

sub pagination {
  ## @overrides
  return 0;
}

1;