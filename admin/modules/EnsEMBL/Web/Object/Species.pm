=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Object::Species;

use strict;

use parent qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager(qw(Production Species));
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
      'maxlength' => '20',
      'required'  => 1
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
