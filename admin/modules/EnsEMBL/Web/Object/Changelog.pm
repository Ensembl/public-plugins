package EnsEMBL::Web::Object::Changelog;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

sub default_action {
  return 'Summary';
}

sub requested_release {
  ## Gets the requested release
  ## @return integer
  my $self = shift;
  return $self->{'_req_release'} ||= $self->hub->param('release') || $self->current_release;
}

sub current_release {
  ## Gets the current release
  ## @return integer
  my $self = shift;
  $self->{'_curr_release'} ||= $self->hub->species_defs->ENSEMBL_VERSION;
}

sub fetch_for_summary {
  ## Populates rose_objects from db for summary page
  return shift->fetch_for_display(@_);
}

sub fetch_for_textsummary {
  ## Populates rose_objects with the changelogs needed to display in the TextSummary page
  my $self = shift;

  $self->rose_objects($self->manager_class->fetch($self->_get_with_objects_params('Display', {
    'query'   => ['release_id', $self->requested_release],
    'sort_by' => 'team'
  })));
}

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('Changelog');
}

sub get_count {
  ## @overrides
  my $self = shift;
  return $self->SUPER::get_count({'query' => ['release_id', $self->requested_release]});
}

sub fetch_for_display {
  ## @overrides
  my $self = shift;

  $self->SUPER::fetch_for_display({'sort_by', 'team', $self->hub->param('id') ? () : ('query', ['release_id', $self->requested_release])}); #ignore release number if id provided for the record
}

sub fetch_for_list {
  ## @overrides
  my $self = shift;

  $self->SUPER::fetch_for_list({'sort_by', 'team', $self->hub->param('id') ? () : ('query', ['release_id', $self->requested_release])}); #ignore release number if id provided for the record
}

sub fetch_for_select {
  ## @overrides
  my $self          = shift;

  $self->SUPER::fetch_for_select({
    'sort_by' => 'title',
    'query'   => ['release_id', $self->requested_release]
  });
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    release_id        => {
      'type'      => 'noedit',
      'label'     => 'Release',
      'value'     => $self->requested_release,
      'no_input'  => 0
    },
    team              => {
      'type'      => 'dropdown',
      'label'     => 'Team'
    },
    title             => {
      'type'      => 'string',
      'label'     => 'Title',
      'required'  => 1
    },
    species           => {
      'type'      => 'dropdown',
      'label'     => 'Species affected',
      'is_null'   => 'All Species',
      'required'  => 1
    },
    content           => {
      'type'      => 'html',
      'label'     => 'Content',
      'class'     => '_tinymce',
    },
    status            => {
      'type'      => 'dropdown',
      'label'     => 'Status'
    },
    assembly          => {
      'type'      => 'dropdown',
      'label'     => 'Is this a new assembly?',
      'values'    => [{'value' => 'Y', 'caption' => 'Yes'}, {'value' => 'N', 'caption' => 'No'}]
    },
    gene_set          => {
      'type'      => 'dropdown',
      'label'     => 'Has the gene set changed?',
      'values'    => [{'value' => 'Y', 'caption' => 'Yes'}, {'value' => 'N', 'caption' => 'No'}]
    },
    repeat_masking    => {
      'type'      => 'dropdown',
      'label'     => 'Has the repeat masking changed?',
      'values'    => [{'value' => 'Y', 'caption' => 'Yes'}, {'value' => 'N', 'caption' => 'No'}]
    },
    stable_id_mapping => {
      'type'      => 'dropdown',
      'label'     => 'Does it need stable ID mapping?',
      'values'    => [{'value' => 'Y', 'caption' => 'Yes'}, {'value' => 'N', 'caption' => 'No'}]
    },
    affy_mapping      => {
      'type'      => 'dropdown',
      'label'     => 'Does it need affy mapping?',
      'values'    => [{'value' => 'Y', 'caption' => 'Yes'}, {'value' => 'N', 'caption' => 'No'}]
    },
    variation_pos_changed => {
      'type'      => 'dropdown',
      'label'     => 'Has any variation position changed? (density features implications)',
      'values'    => [{'value' => 'Y', 'caption' => 'Yes'}, {'value' => 'N', 'caption' => 'No'}]
    },
    db_status         => {
      'type'      => 'dropdown',
      'label'     => 'Database changed'
    },
    priority          => {
      'type'      => 'dropdown',
      'label'     => 'Priority',
      'values'    => [{'value' => '1', 'caption' => 'Low'}, {'value' => '2', 'caption' => 'Normal'}, {'value' => '3', 'caption' => 'High'}, {'value' => '4', 'caption' => 'Very high'}]
    },
    notes             => {
      'type'      => 'text',
      'label'     => 'Notes'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    team              => {'title' => 'Team',       'width' => '20%'},
    title             => {'title' => 'Title',      'width' => '40%'},
    created_by_user   => {'title' => 'Created by', 'width' => '20%'},
    status            => {'title' => 'Status',     'width' => '20%'}
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'declaration',
    'plural'   => 'declarations'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

1;
