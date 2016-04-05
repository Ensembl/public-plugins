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

package EnsEMBL::Web::Component::Tools::FileChameleon::InputForm;

use strict;
use warnings;

use EnsEMBL::Web::FileChameleonConstants qw(INPUT_FORMATS);

use parent qw(
  EnsEMBL::Web::Component::Tools::FileChameleon
  EnsEMBL::Web::Component::Tools::InputForm
);

sub form_header_info {
  ## Abstract method implementation
  return '';  
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self            = shift;
  my $species         = $self->object->species_list;
  my $form            = $self->new_tool_form;
  my $input_formats   = INPUT_FORMATS;
  my $input_fieldset  = $form->add_fieldset({'no_required_notes' => 1});

  # Species dropdown list with stt classes to dynamically toggle other fields
  $input_fieldset->add_field({
    'label'         => 'Species',
    'elements'      => [{
      'type'          => 'speciesdropdown',
      'name'          => 'species',
      'values'        => [ map {
        'value'         => $_->{'value'},
        'caption'       => $_->{'caption'},
        'class'         => '_stt'
      }, @$species ]
    }, {
      'type'          => 'noedit',
      'value'         => 'Assembly: '. join('', map { sprintf '<span class="_stt_%s" rel="%s">%s</span>', $_->{'value'}, $_->{'assembly'}, $_->{'assembly'} } @$species),
      'no_input'      => 1,
      'is_html'       => 1
    }]
  });

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this data (optional)'
  });

  $input_fieldset->add_field({
    'type'          => 'url',
    'name'          => 'url',
    'label'         => 'Provide file URL',
    'size'          => 30,
    'class'         => 'url'
  });
  
  $input_fieldset->add_field({
    'type'          => 'dropdown',
    'name'          => 'format',
    'label'         => 'Input file format',
    'values'        => $input_formats,
    'class'         => '_stt format'
  });
 
  
  $self->add_buttons_fieldset($form, {'reset' => 'Clear', 'cancel' => 'Close form'});

  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return { };
}

sub js_panel {
  ## @override
  return 'FileChameleonForm';
}

1;
