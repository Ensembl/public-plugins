=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::AttribType;

use strict;

use parent qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager(qw(Production AttribType));
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    code        => {
      'type'      => 'string',
      'label'     => 'Code',
      'required'  => 1,
      'maxlength' => 20
    },
    name        => {
      'type'      => 'string',
      'label'     => 'Name',
      'required'  => 1
    },
    description => {
      'type'      => 'text',
      'label'     => 'Description'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    code        => 'Code',
    name        => 'Name',
    description => 'Description'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'attribute type',
    'plural'   => 'attribute types'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}
1;
