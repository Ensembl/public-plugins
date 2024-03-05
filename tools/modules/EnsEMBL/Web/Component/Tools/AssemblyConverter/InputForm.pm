=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::AssemblyConverter::InputForm;

use strict;
use warnings;

use EnsEMBL::Web::AssemblyConverterConstants qw(INPUT_FORMATS);

use parent qw(
  EnsEMBL::Web::Component::Tools::AssemblyConverter
  EnsEMBL::Web::Component::Tools::InputForm
);

sub form_header_info {
  ## Abstract method implementation
  return shift->tool_header({'reset' => 'Clear form', 'cancel' => 'Close'}).'<p class="info">This online tool currently uses <a href="http://crossmap.sourceforge.net">CrossMap</a>,
          which supports a limited number of formats (see our online documentation for
          <a href="/info/website/upload/index.html#formats">details of the individual data formats</a> listed below).
          CrossMap also discards metadata in files, so track definitions, etc, will be lost on conversion.</p>';
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
    'type'          => 'dropdown',
    'name'          => 'species',
    'class'         => '_stt',
    'values'        => [ map {
      'value'         => $_->{'value'},
      'caption'       => $_->{'caption'},
    }, @$species ]
  });

  $input_fieldset->add_field({
    'label'         => 'Assembly mapping',
    'elements'      => [ map {
      'type'          => 'dropdown',
      'name'          => 'mappings_for_'.$_->{'value'},
      'values'        => $_->{'mappings'},
      'element_class' => '_stt_'.$_->{'value'},
    }, @$species],
  });

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this job (optional)'
  });

  $input_fieldset->add_field({
    'type'          => 'dropdown',
    'name'          => 'format',
    'label'         => 'Input file format',
    'values'        => $input_formats,
    'class'         => '_stt format'
  });

  $input_fieldset->add_field({
    'label'         => 'Either paste data',
    'elements'      => [ map {
      'type'          => 'text',
      'name'          => 'text_'.$_->{'value'},
      'element_class' => '_stt_'.$_->{'value'},
      'value'         => $_->{'example'},
    }, @$input_formats ]
  });

  $input_fieldset->add_field({
    'type'          => 'file',
    'name'          => 'file',
    'label'         => 'Or upload file',
    'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $self->hub->species_defs->ENSEMBL_TOOLS_CGI_POST_MAX->{'AssemblyConverter'} / 1048576)
  });

  $input_fieldset->add_field({
    'type'          => 'url',
    'name'          => 'url',
    'label'         => 'Or provide file URL',
    'size'          => 30,
    'class'         => 'url'
  });

  $self->add_buttons_fieldset($form);

  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## @override
  return 'AssemblyConverterForm';
}

1;
