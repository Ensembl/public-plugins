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

package EnsEMBL::Web::Component::Tools::Blast::InputForm;

use strict;
use warnings;

use EnsEMBL::Web::BlastConstants qw(:all);
use HTML::Entities qw(encode_entities);

use parent qw(
  EnsEMBL::Web::Component::Tools::Blast
  EnsEMBL::Web::Component::Tools::InputForm
);

sub _init {
  ## Make the Ajax request for loading this component via POST in case query_sequence is there.
  my $self = shift;
  $self->SUPER::_init(@_);
  $self->ajaxable($self->hub->param('query_sequence') ? 'post' : 1);
}

sub form_header_info {
  ## Abstract method implementation
  my $self = shift;
  
  return $self->tool_header({'reset' => 'Clear form', 'cancel' => 'Close'});
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self      = shift;
  my $hub       = $self->hub;
  my $options   = $self->object->get_blast_form_options->{'options'};
  my $form      = $self->new_tool_form({'class' => 'blast-form'});
  my $fieldset  = $form->add_fieldset;
  my $has_seqid = $hub->species_defs->ENSEMBL_BLAST_BY_SEQID;
  my %tools     = @{$self->hub->species_defs->ENSEMBL_TOOLS_LIST};
  my $msg       = $self->species_specific_info($self->current_species, $tools{'Blast'}, 'Blast', 1);  

  my $query_seq_field = $fieldset->add_field({
    'label'           => 'Sequence data',
    'field_class'     => '_adjustable_height',
    'helptip'         => $has_seqid
                            ? 'Enter sequence as plain text or in FASTA format, or enter a sequence ID or accession from EnsEMBL, EMBL, UniProt or RefSeq'
                            : 'Enter sequence as plain text or in FASTA format',
    'elements'        => [{
      'type'            => 'div',  # container used by js for adding sequence divs
      'element_class'   => '_sequence js_sequence_wrapper hidden',
    }, {
      'type'            => 'div',  # other sequence input elements will get wrapped in this one later
      'element_class'   => '_sequence_field',
      'children'        => [{'node_name' => 'div', 'class' => 'query_sequence_wrapper'}]
    }, {
      'type'            => 'text',
      'value'           =>  sprintf('Maximum of %s sequences (%s)', MAX_NUM_SEQUENCES, $has_seqid ? 'type in plain text, FASTA or sequence ID' : 'type in plain text or FASTA'),
      'class'           => 'inactive query_sequence',
      'name'            => 'query_sequence',
    }, {
      'type'            => 'noedit',
      'value'           => 'Or upload sequence file',
      'no_input'        => 1,
      'element_class'   => 'file_upload_element'
    }, {
      'type'            => 'file',
      'name'            => 'query_file',
      'element_class'   => 'file_upload_element'
    }, {
      'type'            => 'radiolist',
      'name'            => 'query_type',
      'values'          => $options->{'query_type'},
    }]
  });
  my $query_seq_elements = $query_seq_field->elements;

  # add a close button to the textarea element
  $query_seq_elements->[2]->prepend_child('span', {'class' => 'sprite cross_icon _ht', 'title' => 'Cancel'});

  # wrap the sequence input elements
  $query_seq_elements->[1]->first_child->append_children(map { $query_seq_elements->[$_]->remove_attribute('class', $query_seq_field->CSS_CLASS_ELEMENT_DIV); $query_seq_elements->[$_]; } 2..4);

  my $species_defs    = $hub->species_defs;
  # Pass the favourite species as default species. This will be used if action = Multi.
  # Else default species is set in javascript.
  my $default_species = $hub->get_favourite_species->[0];

  my @species         = $hub->param('species') || 
                        ($hub->species ne 'Multi' ? $hub->species : $default_species) || ();

  my $list            = join '', map { '<li>' . $self->object->getSpeciesDisplayHtml($_) . '</li>' } @species;
  my $checkboxes      = join '', map { sprintf('<input type="checkbox" name="species" value="%s" checked>%s', $_, $_) } @species;

#  my $modal_uri       = $hub->url('Component', {qw(type Tools action Blast function TaxonSelector/ajax)});
  my $modal_uri       = $hub->url('MultiSelector', {
                          qw(type Tools action Blast function TaxonSelector),
                          s => $default_species,
                          multiselect => 1,
                          referer_type => $hub->type,
                          referer_action => $hub->action
                        });

  my $species_list   = $self->object->species_list;
  my $species_form_data;

  foreach (@$species_list) {

    # To send classes and other info needed for form data
    $species_form_data->{$_->{'value'}}->{'img_url'} = $_->{'img_url'};
    $species_form_data->{$_->{'value'}}->{'display_name'} = $_->{'caption'};
    $species_form_data->{$_->{'value'}}->{'vep_assembly'} = $_->{'assembly'};    
  }

  my $species_select  = $form->append_child('div', {
    'class'       => 'js_panel taxon_selector_form ff-right',
    'children'    => [{
      'node_name' => 'input',
      'class'     => 'panel_type',
      'value'     => 'ToolsSpeciesList',
      'type'      => 'hidden',
    }, {
      'node_name' => 'div',
      'class'     => 'species_form_data',
      'data-species_form_data'     => encode_entities($self->jsonify($species_form_data)),
    }, {
      'node_name' => 'input',
      'name'      => 'multiselect',
      'value'     => 1,
      'type'      => 'hidden',
    }, {
      'node_name' => 'div',
      'class'     => 'list-wrapper',
      'children'  => [{
        'node_name'  => 'ul',
        'class'      => 'list',
        'inner_HTML' => "$list"
      },
      {
        'node_name' => 'div',
        'class'     => 'links',
        'children'     => [{
          'node_name'  => 'a',
          'class'      => 'modal_link data add_species_link',
          'href'       => $modal_uri,
          'inner_HTML' => 'Change species'
        },
        {
          'node_name'   => 'div',          
          'inner_HTML'  => $msg,
          'class'       => 'assembly_msg italic'        
        }]
      }]
    }, {
      'node_name'  => 'div',
      'class'      => 'checkboxes',
      'inner_HTML' => "$checkboxes"
    }]
  });

  my $search_against_field = $fieldset->add_field({
    'label'           => 'Search against',
    'field_class'     => '_adjustable_height',
  });
  $search_against_field->append_child($species_select);

  for (@{$options->{'db_type'}}) {

    $search_against_field->add_element({
      'type'            => 'radiolist',
      'name'            => 'db_type',
      'element_class'   => 'blast_db_type',
      'values'          => [ $_ ],
      'inline'          => 1
    });

    $search_against_field->add_element({
      'type'            => 'dropdown',
      'name'            => "source_$_->{'value'}",
      'element_class'   => 'blast_source',
      'values'          => $options->{'source'}{$_->{'value'}},
      'inline'          => 1
    });
  }

  $fieldset->add_field({
    'label'           => 'Search tool',
    'elements'        => [{
      'type'            => 'dropdown',
      'name'            => 'search_type',
      'class'           => '_stt',
      'values'          => $options->{'search_type'}
    }]
  });

  # Search sensitivity config sets
  my @sensitivity_elements;
  my @field_classes;
  my ($config_options, $all_config_sets) = CONFIGURATION_SETS;

  for (@{$options->{'search_type'}}) {

    my $search_type = $_->{'value'};

    if (my $config_sets = $all_config_sets->{$search_type}) {

      push @sensitivity_elements, {
        'type'          => 'dropdown',
        'name'          => "config_set_$search_type",
        'element_class' => "_stt_$search_type",
        'values'        => [ grep { $config_sets->{$_->{'value'}} } @$config_options ]
      };
      push @field_classes, "_stt_$search_type";
    }
  }

  if (@sensitivity_elements) {
    $fieldset->add_field({
      'label'       => 'Search Sensitivity:',
      'elements'    => \@sensitivity_elements,
      'field_class' => \@field_classes
    });
  }

  $fieldset->add_field({
    'label'           => 'Description (optional):',
    'type'            => 'string',
    'name'            => 'description',
  });

  # Advanced config options
  my $extra_fieldset  = $form->add_fieldset();
  $extra_fieldset->add_field({ 'label' => 'Additional configurations:' });  
  my $extra_container  = $form->add_fieldset({'no_required_notes' => 1, class => "extra-options-fieldset"});
  
  my $config_fields   = CONFIGURATION_FIELDS;
  my $config_defaults = CONFIGURATION_DEFAULTS;
   
  my @search_types    = map $_->{'value'}, @{$options->{'search_type'}};
  my %stt_classes     = map {$_ => "_stt_$_"} @search_types; # class names for selectToToggle

  while (my ($config_type, $config_field_group) = splice @$config_fields, 0, 2) {

    my $config_fieldset = $form->add_fieldset();
    

    my %wrapper_class;

    while (my ($element_name, $element_params) = splice @{$config_field_group->{'fields'}}, 0, 2) {
      my $field_params = { map { exists $element_params->{$_} ? ($_ => delete $element_params->{$_}) : () } qw(field_class label helptip notes head_notes inline) };
      $field_params->{'elements'} = [];

      my %field_class;
      my $name;

      ## add one element for each with its own default value for each valid search type
      foreach my $search_type_value (@search_types) {        
        for ($search_type_value, 'all') {            
          if (exists $config_defaults->{$_}{$element_name}) {       
            my $element_class = $stt_classes{$search_type_value};       
            
            if(defined $element_params->{elements}) {        
              for my $el (@{$element_params->{elements}}) {
                $name = "${search_type_value}__$el->{name}";
                push @{$field_params->{'elements'}}, {
                  'name'          => ($name =~/__gap_dna$/ && $el->{group}) ? "${search_type_value}__$el->{name}__$el->{group}" : "${search_type_value}__$el->{name}",
                  'values'        => $el->{values},                  
                  'class'         => $el->{class},
                  'value'         => $config_defaults->{$_}{$element_name},
                  'element_class' => $el->{element_class}." $element_class",
                  'type'          => $el->{type}
                };
              }              
            } else { 
              push @{$field_params->{'elements'}}, {
                %{$self->deepcopy($element_params)},
                'name'          => "${search_type_value}__${element_name}",
                'value'         => $config_defaults->{$_}{$element_name},
                'element_class' => $element_class
              };
            }
           
            $field_class{$element_class}    = 1; # adding same class to the field makes sure the field is only visible if at least one of the elements is visible            
            $wrapper_class{$element_class}  = 1; # adding same class to the config wrapper div makes sure the div is only visible if at least one of the field is visible

            last;
          }
        }
      }

      my $field = $config_fieldset->add_field($field_params);
      $field->set_attribute('class', [ keys %field_class ]) unless keys %field_class == keys %stt_classes; # if all classes are there, this field is actually never hidden.
    }

    $self->togglable_fieldsets($extra_container, {
      'class' => scalar keys %wrapper_class == scalar keys %stt_classes ? [] : [ keys %wrapper_class ], # if all classes are there, the wrapper div is actually never hidden.
      'title' => ucfirst "$config_type options" =~ s/_/ /gr,
      'desc'  => $config_field_group->{'caption'}
    }, $config_fieldset);
  }

  # Run Button
  $self->add_buttons_fieldset($form);

  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## Returns the name of the js panel to be used to initialise the JavaScript on this form
  ## @return String
  return 'BlastForm';
}

sub js_params {
  ## @override
  ## Add extra BLAST specific js params
  my $self    = shift;
  my $hub     = $self->hub;
  my $params  = $self->SUPER::js_params(@_);
  my $options = $self->object->get_blast_form_options;

  $params->{'valid_combinations'}     = $options->{'combinations'};
  $params->{'missing_sources'}        = $options->{'missing_sources'};
  $params->{'blat_availability'}      = $options->{'blat_availability'};
  $params->{'restrictions'}           = $options->{'restrictions'};
  $params->{'max_sequence_length'}    = MAX_SEQUENCE_LENGTH;
  $params->{'dna_threshold_percent'}  = DNA_THRESHOLD_PERCENT;
  $params->{'max_number_sequences'}   = MAX_NUM_SEQUENCES;
  $params->{'read_file_url'}          = $hub->url('Json', {'function' => 'read_file'});
  $params->{'fetch_sequence_url'}     = $hub->url('Json', {'function' => 'fetch_sequence'}) if $hub->species_defs->ENSEMBL_BLAST_BY_SEQID;
  $params->{'sensitivity_configs'}    = [ CONFIGURATION_SETS ]->[1];

  # Add a 'edit job' param if coming from "BLAST this sequence" link
  if (my $existing_seq = $hub->param('query_sequence')) {
    my $edit_job = {'sequence' => {'sequence' => $existing_seq}};
    if (my $search_type = $hub->param('search_type')) {
      $edit_job->{'search_type'} = $search_type;
    }
    if (my $source = $hub->param('source')) {
      $edit_job->{'source'} = $source;
    }
    $params->{'edit_jobs'} = [ $edit_job ];
  }

  return $params;
}

1;
