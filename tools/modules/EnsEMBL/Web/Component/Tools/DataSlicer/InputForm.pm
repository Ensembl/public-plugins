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

package EnsEMBL::Web::Component::Tools::DataSlicer::InputForm;

use strict;
use warnings;

use EnsEMBL::Web::DataSlicerConstants qw(FILE_FORMATS);

use parent qw(
  EnsEMBL::Web::Component::Tools::DataSlicer
  EnsEMBL::Web::Component::Tools::ThousandGenomeInputForm
);

sub form_header_info {
  my $self  = shift;
  return $self->tool_header({'reset' => 'Clear form', 'cancel' => 'Close'}).'<p class="info">This tool will get a subset of data from a BAM or VCF file.</p>';
}

sub js_params {
  ## Returns parameters to be passed to JavaScript panel
  ## @return Hashref of keys to value - if value is hash or array, it gets passed as JSON object

  my $self    = shift;
  my $hub     = $self->hub;
  my $params  = $self->SUPER::js_params(@_);

  # This is ajax request for 1000 genomes to retrieve file content from sample file url
  $params->{'get_individuals'}     = $hub->url('Json', {'function' => 'get_individuals'});

  return $params;
}

sub get_cacheable_form_node {
  ## Overwriting parent ThousandGenomeInputForm by adding region_check hidden input
  my $self    = shift;

  my $options->{file_format}      = FILE_FORMATS;
  $options->{vcf_filters}         = 1; #use in parent class form
  $options->{different_pop_value} = 1; #use in parent class form to set different values for population box
  
  my $form        = $self->common_form($options);  
  my $fieldset    = $form->fieldsets->[0];
 
  $fieldset->add_field({
    'type'          => 'string',
    'name'          => 'region_check',    
    'value'         => '2500000',
    'field_class'   => 'hidden',
  });
  
  $fieldset->add_field({
    'type'          => 'string',
    'name'          => 'pop_caption',    
    'value'         => '',
    'field_class'   => 'hidden',
  });  
  
  #field to know which tool it is
  $fieldset->add_field({
    'type'          => 'string',
    'name'          => 'which_tool',    
    'value'         => 'data_slicer',
    'field_class'   => 'hidden',
  });
  
  $fieldset->append_child('div',  {
    class       => '_stt_individuals',
    children    => [  
      $fieldset->add_field({
        'type' => 'String',
        'name'        => 'ind_list',
        'label'       => 'Enter comma separated list of individuals',
        'notes'       => 'maximum 372 individuals',
        'field_class' => 'hidden _individuals  _stt_vcf',
        'size'        => '60',
        'value'       => '' 
      }),
      $fieldset->add_field({
        'type'          => 'dropdown',
        'name'          => 'individuals_box',
        'label'         => 'Alternatively, select one or more individuals from the scrollable list',
        'values'        => [],
        'size'          => '10',
        'class'         => 'individuals_listbox',
        'field_class'   => 'hidden _individuals _stt_vcf',
        'multiple'      => '1',
        'notes'         => "maximum 416 individuals",
      })
    ]});
  
  $fieldset->add_field({
    'type'          => 'url',
    'name'          => 'bam_file_url',
    'label'         => qq{BAM file URL},
    'size'          => 30,
    'class'         => 'url',
    'field_class'   => 'hidden _stt_bam',
    'notes'         => 'e.g: https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/data/NA06984/alignment/NA06984.454.MOSAIK.SRP000033.2009_11.bam'
  });    
  
  $fieldset->add_field({
    'type'          => 'checkbox',
    'name'          => 'bai_file',    
    'value'         => '1',
    'label'         => 'Generate .bai file',
    'field_class'   => '_stt_bam',   
  });
  
  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## use generic js for 1000genome form
  return 'DataSlicerForm';
}

#Overwriting parent one to remove ALL in the population list
sub get_populations {
  my $self    = shift;

  my $pops = $self->SUPER::get_populations(@_);
  splice @$pops, 0,1; # ALL is the first element in the array

  return $pops;
}

1;
