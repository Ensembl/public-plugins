package EnsEMBL::Web::Object::AnalysisWebdata;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('AnalysisWebData');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  my $ad;
  $ad = $self->hub->param('ad') and $ad = $self->rose_manager('AnalysisDescription')->fetch_by_primary_key($ad) and $ad = {'value' => $ad->get_primary_key_value, 'caption' => $ad->get_title};
  return [
    analysis_description => {
      'type'      => 'noedit',
      'label'     => 'For Analysis Description',
      %{$ad || {}}
    },
    species           => {
      'type'      => 'dropdown',
      'label'     => 'Species',
      'required'  => 1,
    },
    db_type           => {
      'type'      => 'dropdown',
      'label'     => 'Database Type',
    },
    displayable       => {
      'type'      => 'dropdown',
      'label'     => 'Displayable',
      'values'    => [{'caption' => 'Yes', 'value' => '1'}, {'caption' => 'No', 'value' => '0'}]
    },
    web_data          => {
      'type'      => 'radiolist',
      'label'     => 'Web Data',
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
    species     => 'Species',
    db_type     => 'DB Type',
    displayable => 'Displayable',
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

1;