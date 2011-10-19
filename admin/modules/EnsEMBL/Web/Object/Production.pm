package EnsEMBL::Web::Object::Production;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

sub fetch_for_search {
  my $self = shift;
  $self->rose_objects($self->manager_class->get_objects(
    'with_objects'  => ['analysis_description', 'species', 'web_data'],
    'sort_by'       => 'analysis_description.display_label'
  ));
}

sub fetch_for_analysiswebdata {
  shift->fetch_for_search;
}

sub fetch_for_logicname {
  my $self  = shift;
  my $hub   = $self->hub;

  if ($hub->param('id')) {
    $self->fetch_for_list;
    return;
  }

  my $query = $self->_get_filter_query;
  if (@$query) {
    $self->rose_objects($self->manager_class->fetch_by_page($self->pagination, $self->get_page_number, {
      'with_objects'  => ['analysis_description', 'species', 'web_data'],
      'sort_by'       => 'analysis_description.logic_name',
      'query'         => $query
    }));
  }
}

sub get_count {
  ## @overrides
  my $self = shift;
  
  return $self->SUPER::get_count({'query' => $self->_get_filter_query});
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
      'required'  => 1,
    },
    db_type           => {
      'type'      => 'dropdown',
      'label'     => 'Database type',
    },
    web_data          => {
      'type'      => 'radiolist',
      'label'     => 'Web Data',
      'is_null'   => 'null',
    },
    displayable       => {
      'type'      => 'dropdown',
      'label'     => 'Displayable',
      'values'    => [{'value' => '1', 'caption' => 'Yes'}, {'value' => '0', 'caption' => 'No'}]
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    analysis_description  => {'title' => 'Logic Name', 'ensembl_object' => 'AnalysisDesc'},
    species               => 'Species',
    db_type               => 'Database Type',
    web_data              => {'title' => 'Web Data', 'width' => qq(50%), 'ensembl_object' => 'Webdata'},
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
  return 100;
}

sub _get_filter_query {
  ## Private method to read the GET params and return an arrayref of query
  my $self = shift;

  unless (exists $self->{'_filter_query'}) {
    my $hub  = $self->hub;

    $self->{'_filter_query'} = [];
    for (qw(web_data_id analysis_description_id species_id db_type)) {
      my $value = $hub->param($_);
      if ($value || $value eq '0') {
        $_ eq 'web_data_id' and $value eq '0' and $value = undef;
        push @{$self->{'_filter_query'}}, $_, $_ eq 'db_type' ? {'like' => "%$value%"} : $value;
      }
    }
  }

  return $self->{'_filter_query'};
}

1;