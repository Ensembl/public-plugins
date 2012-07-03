package EnsEMBL::Web::Object::Species;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('Species');
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    web_name          => {
      'type'      => 'string',
      'label'     => 'Name on website',
      'required'  => 1,
    },
    db_name           => {
      'type'      => 'string',
      'label'     => 'Name in database',
      'required'  => 1,
    },
    common_name       => {
      'type'      => 'string',
      'label'     => 'Common Name',
      'required'  => 1,
    },
    scientific_name   => {
      'type'      => 'string',
      'label'     => 'Scientific Name',
      'required'  => 1,
    },
    production_name   => {
      'type'      => 'string',
      'label'     => 'Production Name',
      'required'  => 1,
    },
    url_name          => {
      'type'      => 'string',
      'label'     => 'URL Name',
      'required'  => 1,
    },
    attrib_type       => {
      'is_null'   => 'None',
      'type'      => 'dropdown',
      'label'     => 'Attrib Type',
    },
    alias             => {
      'is_null'   => 'No Alias',
      'type'      => 'dropdown',
      'label'     => 'Alias',
    },
    taxon             => {
      'type'      => 'string',
      'label'     => 'Taxon',
      'maxlength' => '20'
    },
    species_prefix    => {
      'type'      => 'string',
      'label'     => 'Prefix',
      'maxlength' => '20'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    web_name        => 'Web name',
    db_name         => 'Db name',
    common_name     => 'Common name',
    scientific_name => 'Sci. name',
    production_name => 'Prod. name',
    url_name        => 'URL name',
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'species',
    'plural'   => 'species'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

1;
