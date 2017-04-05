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

package EnsEMBL::Web::Component::Tools::Forger::InputForm;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::Forger
  EnsEMBL::Web::Component::Tools::InputForm
);

sub form_header_info {
  ## Abstract method implementation
  return '';
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self    = shift;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $object  = $self->object;
  my $form    = $self->new_tool_form;
  my $species = $object->species_list;

  # Input fieldset
  my $input_fieldset = $form->add_fieldset({'no_required_notes' => 1});

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
    'label'         => 'Name for this job (optional)'
  });

  $input_fieldset->add_field({
    'label'         => 'Either paste data',
    'type'          => 'text',
    'name'          => 'text'
  });

  $input_fieldset->add_field({
    'type'          => 'file',
    'name'          => 'file',
    'label'         => 'Or upload file',
    'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $sd->ENSEMBL_TOOLS_CGI_POST_MAX->{'Forger'} / 1048576)
  });

  $input_fieldset->add_field({
    'type'          => 'url',
    'name'          => 'url',
    'label'         => 'Or provide file URL',
    'size'          => 30,
    'class'         => 'url'
  });
  
  $input_fieldset->add_field({
    'type'          => 'dropdown',
    'name'          => 'format',
    'label'         => 'Input file format',
    'values'        =>  [
      { 'value' => 'rsid', 'caption' => 'RSID (List of variations)' },
      { 'value' => 'vcf',  'caption' => 'VCF' },
      { 'value' => 'bed',  'caption' => 'BED' },
    ],    
  });
  
  my $option_fieldset  = $form->add_fieldset();
  $option_fieldset->add_field({
    'type'          => 'checkbox',
    'name'          => 'overlap',
    'label'         => 'Find overlaps only',
    'values'        => "overlap",
  });
  
  $option_fieldset->add_field({
    'type'          => 'radiolist',
    'name'          => 'src',
    'label'         => 'Analysis data from',
    'values'        =>  [
      { 'value' => 'erc',      'caption' => 'Epigenome Roadmap', 'checked' => "checked" },
      { 'value' => 'encode',   'caption' => 'ENCODE' }
    ],
  });  
  
  $option_fieldset->add_field({
    'type'          => 'radiolist',
    'name'          => 'bkgd',
    'label'         => 'Background selection',
    'values'        =>  [
      { 'value' => 'gwas',   'caption' => 'GWAS typing arrays', 'checked' => "checked" },
      { 'value' => 'omni',   'caption' => 'Omni array SNPs' }
    ],
  }); 
  
  $option_fieldset->add_field({
    'type'          => 'dropdown',
    'name'          => 'ld',
    'label'         => 'LD filter ( r<sup>2</sup> )',
    'values'        =>  [
      { 'value' => '0.8', 'caption' => '0.8' },
      { 'value' => '0.1', 'caption' => '0.1' },
      { 'value' => '0.0', 'caption' => 'No filter' },
    ],    
  });  

  $option_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'reps',
    'label'         => 'Background repetitions',    
    'value'         => '100',
    'notes'         => '(setting of 1000 would give more accurate backgrounds but the job will be 3-4 times slower )',
  });
  
  $option_fieldset->add_field({
    'type'          => 'string',
    'value'         => '',
    'label'         => 'Significance thresholds <br><span class="small">( P values before Bonferroni correction )</span>',
    'name'          => 'dummy',
    'class'         => 'hidden',    
  });
  
  $option_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'tmin',
    'label'         => 'High',    
    'value'         => '0.01',    
  });  
  
  $option_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'tmax',
    'label'         => 'Low',    
    'value'         => '0.05',    
  });    
  
  $self->togglable_fieldsets($form, {
    'title' => "Options",
    'desc'  => "Apply different options",
    'open'  => 1,
  }, $option_fieldset);  

  # Run/Close buttons
  $self->add_buttons_fieldset($form, {'reset' => 'Clear', 'cancel' => 'Close form'});

  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## @overrride
  return 'ForgerForm';
}

1;
