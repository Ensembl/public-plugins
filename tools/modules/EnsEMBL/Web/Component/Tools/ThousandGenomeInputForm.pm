=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::ThousandGenomeInputForm;

### Parent class for all 1000genome tools 
### contains the form and other generic function for 1000genome use

use strict;
use warnings;

use EnsEMBL::Web::File::Utils::URL;
use HTML::Entities  qw(encode_entities);

use parent qw(EnsEMBL::Web::Component::Tools::InputForm);

sub js_params {
  ## Returns parameters to be passed to JavaScript panel
  ## @return Hashref of keys to value - if value is hash or array, it gets passed as JSON object

  my $self    = shift;
  my $hub     = $self->hub;
  my $params  = $self->SUPER::js_params(@_);

  # This is ajax request for 1000 genomes to retrieve file content from sample file url
  $params->{'read_sample_file'}     = $hub->url('Json', {'function' => 'read_sample_file'});
  $params->{'genome_file_rest_url'} = $SiteDefs::GENOME_REST_FILE_URL;
  $params->{'files_location_regex'} = $SiteDefs::THOUSANDG_FILE_LOCATION;

  return $params;

}

# function to display the form interface for the 1000 genomes tool
sub common_form {
  my ($self, $options)  = @_;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $object  = $self->object;
  my $form    = $self->new_tool_form;
  my $species = $object->species_list;
  
  my $file_format       = $options->{'file_format'} if exists $options->{'file_format'};
  my $populations_class = $options->{vcf_filters} ? "_stt_populations" : ""; #class for data slicer to hide a specific section
  my $individuals_flag  = $options->{different_pop_value} ?  1 : ""; #flag to set population box values to individuals instead of populations (used by data slicer)
  
  my $sample_tip  = encode_entities('<p>This file lists all the individuals and the population they come from.</p><p><a href="/info/docs/tools/allelefrequency/sample_panel.html"  class="popup">Find out more on what a panel file is.</a></p>');
  my $vcf_tip     = encode_entities('<p>The genotype file should be VCF only.</p><p><a href="/info/website/upload/sample_files/Pulmonary_function.vcf.txt" class="popup"> Example VCF file </a></p>');

  my $populations_list = $SiteDefs::THOUSANDG_POPULATIONS; #Restriction to population phase
  my $collection_formats = [
    { 'value' => 'custom',  'caption' => 'Provide file URLs',  'example' => qq() }
  ];

  foreach my $r (keys %$populations_list) {
    push (@$collection_formats, { 'value' => $r,  'caption' => $populations_list->{$r}, 'selected' => $r eq 'phase3' ?  'true' : '' }); 
  }
  my $phase1_panel       = $SiteDefs::PHASE1_PANEL_URL;
  my $phase3_panel       = $SiteDefs::PHASE3_PANEL_URL;
  my $phase3_male_panel  = $SiteDefs::PHASE3_MALE_URL;

  # Input fieldset
  my $input_fieldset = $form->add_fieldset({'no_required_notes' => 1});

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this job (optional)'
  });

  # Set species to human only
  $input_fieldset->add_field({
    'label'         => 'Species',
    'elements'      => [{
      'type'          => 'noedit',
      'value'         => sprintf('<img class="job-species" src="%sspecies/Homo_sapiens.png" alt="" height="16" width="16">%s', $self->img_url,$sd->species_label("Homo_sapiens", 1)),
      'no_input'      => 1,
      'is_html'       => 1
    }, {
      'type'          => 'noedit',
      'value'         => 'Assembly: '. join('', map { sprintf '<span class="_stt_%s" rel="%s">%s</span>', $_->{'value'}, $_->{'assembly'}, $_->{'assembly'} } @$species),
      'no_input'      => 1,
      'is_html'       => 1      
    }, {
      'type'          => 'string',
      'name'          => 'species',
      'size'          => 30,
      'value'         => (map { sprintf ('%s', $_->{'value'}) } @$species),
      'class'         => 'hidden'
    }]
  });
  
  $input_fieldset->add_field({
    'label'         => 'Choose file format',
    'type'          => 'dropdown',
    'name'          => 'file_format',
    'values'        => $file_format,
    'class'         => '_stt'  
  }) if($file_format);  

  $input_fieldset->add_field({
    'label'         => 'Region Lookup',
    'type'          => 'string',
    'name'          => 'region',
    'notes'         => 'e.g. 1:1-50000'
  });
  
  my $pop_div = $input_fieldset->append_child('div', {
    class     => $file_format ? '_stt_vcf' : '',
    children  =>[$input_fieldset->add_field({
      'label'         => 'Choose data collections or provide your own file URLs',
      'elements'      => [{
        'type'          => 'dropdown',
        'name'          => 'collection_format',
        'values'        => $collection_formats,
        'class'         => ['_stt', '_sttmulti'],
      }, {
        'type'          => 'noedit',
        'value'         => "<span class='_span_url _stt_phase3 _stt_phase1'>Genotype File URL:</span>",
        'name'          => "generated_file_url",
        'is_html'       => 1
      }, {
        'type'          => 'noedit',
        'value'         => "<div class='$populations_class'><span class='_sample_url_phase3 _stt_phase3'>Sample-population file URL: $phase3_panel</span><span class='_sample_url_phase1 _stt_phase1' style='display: none'>Sample-population file URL: $phase1_panel</span><span class='_sample_url_phase3_male _stt_phase3_male hidden'>Sample-population file URL: $phase3_male_panel</span></div>",
        'no_input'      => 1,
        'is_html'       => 1
      }],
    }),  
    $input_fieldset->add_field({
      'type'          => 'url',
      'name'          => 'custom_file_url',
      'label'         => qq{<span class="ht _ht"><span class="_ht_tip hidden">$vcf_tip</span>Genotype file URL</span>},
      'size'          => 30,
      'class'         => 'url',
      'field_class'   => 'hidden _stt_custom',
      'notes'         => 'e.g: https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr1.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz'
    }),
    $input_fieldset->add_field({
    'type'          => 'radiolist',
    'name'          => 'vcf_filters',
    'label'         => '<span class="ht _ht"><span class="_ht_tip hidden">Choose whether to apply any filtering to the output.</span>Filters</span>',
    'values'        => [{ 'value' => 'null',  'caption' => 'No filtering', 'checked' => 'true' }, { 'value' => 'individuals',  'caption' => 'By individuals' }, { 'value' => 'populations',  'caption' => 'By populations'}],
    'field_class'   => '_stt_vcf _vcf_filters hidden', 
    'class'         => '_stt',
    }),
    $input_fieldset->append_child('div',  {
      class       => $options->{vcf_filters} ?  '_stt_populations' : '',
      children    => [
        $input_fieldset->add_field({
          'type'          => 'url',
          'name'          => 'custom_sample_url',
          'label'         => qq{<span class="ht _ht"><span class="_ht_tip hidden">$sample_tip</span>Sample-population mapping file URL</span>}, #documentation is in docs/htdocs; move to help db if outreach want to control this
          'size'          => 30,
          'class'         => 'url',
          'notes'         => 'e.g: https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel',
          'field_class'   => 'hidden _stt_custom _custom_sample_url',
        })]
    }),
    ]
  }); 

  $pop_div->append_child('div',  {
    class       => $options->{vcf_filters} ?  '_stt_populations' : '',
    children    => [
      $input_fieldset->add_field({
        'type'          => 'dropdown',
        'name'          => 'phase3_populations',
        'label'         => 'Select one or more phase 3 populations',
        'values'        => $self->get_populations($phase3_panel, $individuals_flag, $form),
        'size'          => '10',
        'class'         => 'tools_listbox',
        'field_class'   => 'hidden _stt_phase3  population',
        'multiple'      => '1'
      }),  
      $input_fieldset->add_field({
        'type'          => 'dropdown',
        'name'          => 'phase1_populations',
        'label'         => 'Select one or more phase 1 populations',
        'values'        => $self->get_populations($phase1_panel, $individuals_flag, $form),
        'size'          => '10',
        'class'         => 'tools_listbox',
        'field_class'   => 'hidden _stt_phase1  population',
        'multiple'      => '1'
      }),  
      $input_fieldset->add_field({
        'type'          => 'dropdown',
        'name'          => 'phase3_male_populations',
        'label'         => 'Select one or more phase 3(male) populations',
        'values'        => $self->get_populations($phase3_male_panel, $individuals_flag, $form),
        'size'          => '10',
        'class'         => 'tools_listbox',
        'field_class'   => 'hidden population _stt_phase3_male ',
        'multiple'      => '1'
      }),
      $input_fieldset->add_field({
        'type'          => 'dropdown',
        'name'          => 'custom_populations',
        'label'         => 'Select one or more populations',
        'values'        => [],
        'size'          => '10',
        'class'         => 'tools_listbox',
        'field_class'   => 'hidden population custom_population _stt_custom_population ',
        'multiple'      => '1'
      })]
  }) if(!$options->{no_population});  
  
  # Run/Close buttons
  $self->add_buttons_fieldset($form);

  return $form; 
  
}

# Get all populations from the panel file (url based) - we have an ajax request based function inside JSONserver/Tools.pm
sub get_populations {
  my ($self, $population_url, $individuals_flag, $form) = @_;
  
  my $hub  = $self->hub;   
  my $pops = [];
  my $args = {'no_exception' => "1" };
  my $proxy = $hub->web_proxy;
  
  $args->{proxy}  = $proxy ? $proxy : "";  
  my $html        = EnsEMBL::Web::File::Utils::URL::read_file($population_url, $args);
   
  my $sample_pop; 

  if ( $html ){
    foreach (split("\n",$html)){
      next if(!$_ || $_ =~ /sample/gi); #skip if empty or skip header if there is one
      my ($sam, $pop, $plat) = split(/\t/, $_);
      $sample_pop->{$pop} ||= [];
      push @{$sample_pop->{$pop}}, $sam;
    }
    push @$pops, { caption =>'ALL', value=>'ALL', selected=>'1'};
    for my $population (sort {$a cmp $b} keys %{$sample_pop}) {
      my $ind_list = join(',' , @{$sample_pop->{$population}}) if($individuals_flag);
      push @{$pops}, { value => $ind_list ? $ind_list : $population,  caption => $population };
    }    
  } else {
    push @$pops, { caption =>'ERROR', value=>'null', selected=>'1'};   
    $form->set_flag("error");
  } 

  return $pops;  
}

1;
