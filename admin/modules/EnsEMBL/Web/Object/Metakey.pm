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

package EnsEMBL::Web::Object::Metakey;

use strict;

use parent qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager(qw(Production MetaKey));
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    name              => {
      'type'      => 'string',
      'label'     => 'Name'
    },
    is_optional       => {
      'type'      => 'dropdown',
      'label'     => 'Is this meta key optional?',
      'values'    => [{'value' => '0', 'caption' => 'No'}, {'value' => '1', 'caption' => 'Yes'}]
    },
    db_type           => {
      'type'      => 'dropdown',
      'label'     => 'Database Type',
    },
    species           => {
      'type'      => 'dropdown',
      'label'     => 'Related Species',
    },
    description       => {
      'type'      => 'text',
      'label'     => 'Description',
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    name        => 'Name',
    db_type     => 'Database Type',
    species     => 'Related Species'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'meta key',
    'plural'   => 'meta keys'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}

1;