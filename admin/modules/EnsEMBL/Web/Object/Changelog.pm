package EnsEMBL::Web::Object::Changelog;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

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

sub fetch_for_textsummary {
  ## Populates rose_objects with the changelogs needed to display in the TextSummary page
  my $self = shift;

  my $params = $self->_get_with_objects_params('Display');
  $params->{'query'}    = ['release_id', $self->requested_release];
  $params->{'sort_by'}  = 'team';
  $self->rose_objects($self->manager_class->fetch($params));
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

  my @ids = $self->hub->param('id') || ();
  scalar @ids == 1 and @ids = split ',', $ids[0];
  if (@ids) {
    $self->rose_objects($self->manager_class->fetch_by_primary_keys([@ids], $self->_get_with_objects_params('Display')));
  }
  else {
    my $params = $self->_get_with_objects_params('Display');
    $params->{'query'}    = ['release_id', $self->requested_release];
    $params->{'sort_by'}  = 'team';
    $self->rose_objects($self->manager_class->fetch_by_page($self->pagination, $self->get_page_number, $params));
  }
}

sub fetch_for_list {
  ## @overrides
  my $self = shift;

  my $params = $self->_get_with_objects_params('List');
  $params->{'query'}    = ['release_id', $self->requested_release];
  $params->{'sort_by'}  = 'team';
  $self->rose_objects($self->manager_class->fetch_by_page($self->pagination, $self->get_page_number, $params));
}

sub fetch_for_select {
  ## @overrides
  my $self = shift;

  my $sort_by = $self->manager_class->object_class->TITLE_COLUMN || $self->manager_class->object_class->primary_key;
  $self->rose_objects($self->manager_class->get_objects('query' => ['release_id', $self->requested_release], 'sort_by' => $sort_by));
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
      'label'     => 'Is this a new assembly?'
    },
    gene_set          => {
      'type'      => 'dropdown',
      'label'     => 'Has the gene set changed?'
    },
    repeat_masking    => {
      'type'      => 'dropdown',
      'label'     => 'Has the repeat masking changed?'
    },
    stable_id_mapping => {
      'type'      => 'dropdown',
      'label'     => 'Does it need stable ID mapping?'
    },
    affy_mapping      => {
      'type'      => 'dropdown',
      'label'     => 'Does it need affy mapping?'
    },
    db_status         => {
      'type'      => 'dropdown',
      'label'     => 'Database changed'
    },
    notes             => {
      'type'      => 'text',
      'label'     => 'Notes'
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
    team              => 'Team',
    title             => 'Title',
    created_by_user   => 'Created by',
    status            => 'Status'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'deceleration',
    'plural'   => 'decelerations'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}


1;