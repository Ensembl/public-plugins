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

package EnsEMBL::Web::Object::Attrib;

use strict;

use parent qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager(qw(Production Attrib));
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    value         => {
      'type'      => 'string',
      'label'     => 'Value',
      'required'  => 1,
      'maxlength' => 20
    },
    attrib_type   => {
      'type'      => 'dropdown',
      'label'     => 'Attrib type',
      'required'  => 1,
    },
  ];
}

sub show_columns {
  ## @overrides
  return [
    value   => 'Value',
    attrib_type => {'title' => 'Attrib type', 'ensembl_object' => 'AttribType'},
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'attribute',
    'plural'   => 'attributes'
  };
}

sub permit_delete {
  ## @overrides
  ## Record can not be deleted, but can be set inactive
  return 'retire';
}
1;
