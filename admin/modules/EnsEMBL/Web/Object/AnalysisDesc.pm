=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::AnalysisDesc;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager(qw(Production AnalysisDescription));
}

sub show_fields {
  ## @overrides
  my $self = shift;
  return [
    logic_name        => {
      'type'            => 'string',
      'label'           => 'Logic Name'
    },
    display_label     => {
      'type'            => 'string',
      'label'           => 'Display Label'
    },
    description       => {
      'type'            => 'text',
      'label'           => 'Description'
    },
    db_version        => {
      'type'            => 'dropdown',
      'label'           => 'DB Version',
      'values'          => [{'value' => '1', 'caption' => 'Yes'}, {'value' => '0', 'caption' => 'No'}]
    },
    default_web_data  => {
      'type'            => 'radiolist',
      'label'           => 'Default Web data',
      'field_class'     => 'form-field-scroll',
      'is_null'         => 'None'
    }
  ];
}

sub show_columns {
  ## @overrides
  return [
    logic_name        => 'Logic Name',
    display_label     => 'Display Label',
    description       => 'Description',
    default_web_data  => 'Default Web data'
  ];
}

sub record_name {
  ## @overrides
  return {
    'singular' => 'analysis description',
    'plural'   => 'analysis descriptions'
  };
}

sub permit_delete {
  ## @overrides
  return 'delete';
}

1;