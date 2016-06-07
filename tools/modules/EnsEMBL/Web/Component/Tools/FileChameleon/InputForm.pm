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

use EnsEMBL::Web::FileChameleonConstants qw(INPUT_FORMATS STYLE_FORMATS CONVERSION_FORMATS);

use parent qw(
  EnsEMBL::Web::Component::Tools::FileChameleon
  EnsEMBL::Web::Component::Tools::InputForm
);

sub form_header_info {
  ## Abstract method implementation
  return '<p class="info">To use Ensembl data for your NGS analysis, download files formatted for your analysis tool with the File Chameleon.</p><p><b>Important Note:</b> File chameleon will not do file format conversion.</p>';
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self            = shift;
  my $species         = $self->object->species_list;
  my $form            = $self->new_tool_form;
  my $input_formats   = INPUT_FORMATS;
  my $style_formats   = STYLE_FORMATS;
  my $conversion      = CONVERSION_FORMATS
  my $input_fieldset  = $form->add_fieldset({'legend' => '1. Choose Ensembl file',  'class' => 'tool_h2', 'no_required_notes' => 1});

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
    'type'          => 'dropdown',
    'name'          => 'format',
    'label'         => 'File format',
    'values'        => $input_formats,
    'class'         => 'format'
  });
  
  $input_fieldset->add_field({
    'type'          => 'dropdown',
    'name'          => 'files_list',
    'label'         => 'Files',
    'values'        => [],
    'size'          => '10',
    'class'         => 'tools_listbox'
  });  
  
  $input_fieldset->add_field({
    'type'          => 'noedit',
    'value'         => 'http://',
    'label'         => 'File URL',
    'no_input'      => 1,
    'is_html'       => 1,
    'class'         => '_file_url'
  });  

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this job (optional)'
  });

  my $format_fieldset  = $form->add_fieldset({'legend' => '2. Reformatting',  'class' => 'tool_h2', 'no_required_notes' => 1});
  $format_fieldset->add_field({
    'type'          => 'dropdown',
    'name'          => 'conversion_format',
    'label'         => 'Format suitable for:',
    'values'        => $conversion,
  });  
  
  my $filter_fieldset  = $form->add_fieldset();
  $filter_fieldset->add_field({
    'type'          => 'checklist',
    'name'          => 'chr_filter',
    'label'         => 'Filter chromosome',
    'values'        => [ { 'value' => '1' } ],
    'class'         => '_stt',    
  });
  
  $filter_fieldset->add_field({
    'type'          => 'dropdown',
    'name'          => 'convert_to',
    'label'         => 'Convert chromosome format from',
    'values'        => $style_formats,
    'field_class'   => 'hidden _stt_1'
  });

  $filter_fieldset->add_field({
    'type'          => 'checklist',
    'name'          => 'add_transcript',
    'label'         => 'Add transcript ID',
    'values'        => [ { 'value' => '1' } ],
  });

  $filter_fieldset->add_field({
    'type'          => 'checklist',
    'name'          => 'remap_patch',
    'label'         => 'Remap patches',
    'values'        => [ { 'value' => '1' } ],
  }); 

  $self->togglable_fieldsets($form, {
    'title' => "3. Customise",
    'desc'  => "Customise options for reformatting"
  }, $filter_fieldset);  
  
  
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
