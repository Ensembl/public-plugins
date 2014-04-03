=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::ExternalDb;

use strict;

use parent qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager(qw(Production ExternalDb));
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    external_db_id      => {
      'type'      => 'noedit',
      'label'     => 'External DB ID',
      'value'     => '<i>to be assigned</i>',
      'is_html'   => 1
    },
    db_name             => {
      'type'      => 'string',
      'label'     => 'Name',
      'required'  => 1
    },
    db_release          => {
      'type'      => 'string',
      'label'     => 'Release'
    },
    status              => {
      'type'      => 'dropdown',
      'label'     => 'Status',
      'required'  => 1
    },
    db_display_name     => {
      'type'      => 'string',
      'label'     => 'Display name'
    },
    priority            => {
      'type'      => 'string',
      'label'     => 'Priority'
    },
    type                => {
      'type'      => 'dropdown',
      'label'     => 'Type'
    },
    secondary_db_name   => {
      'type'      => 'string',
      'label'     => 'Secondary db name'
    },
    secondary_db_table  => {
      'type'      => 'string',
      'label'     => 'Secondary db table'
    },
    description         => {
      'type'      => 'text',
      'label'     => 'Description'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    external_db_id  => {'title' => 'Ext. DB ID', 'readonly' => 1},
    db_name         => 'Name',
    db_release      => 'Release',
    status          => 'Status'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'external db',
    'plural'   => 'external dbs'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}
1;