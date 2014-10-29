=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use parent qw(EnsEMBL::Web::Component::Tools::Blast);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $sd              = $hub->species_defs;
  my $object          = $self->object;
  my $cache           = $hub->cache;
  my $form            = $cache ? $cache->get('BLASTFORM') : undef;
  my $species         = $hub->species;
     $species         = $hub->get_favourite_species->[0] if $species =~ /multi|common/i;

  # If cached form not found, generate a new form and save in cache to skip the form generation process next time
  if (!$form) {
    $form = $self->get_form_node->render;
    $cache->set('BLASTFORM', $form) if $cache;
  }

  # Add the non-cacheable fields to this dummy form and replace the placeholders from the actual form HTML
  my $fieldset2 = $self->new_form->add_fieldset;

  # Previous job params for JavaScript
  my $edit_jobs = ($hub->function || '') eq 'Edit' ? $object->get_edit_jobs_data : [];
  if (!@$edit_jobs && (my $existing_seq = $hub->param('query_sequence'))) { # If coming from "BLAST this sequence" link
    $edit_jobs = [ {'sequence' => {'sequence' => $existing_seq}} ];
    if (my $search_type = $hub->param('search_type')) {
      $edit_jobs->[0]{'search_type'} = $search_type;
    }
    if (my $source = $hub->param('source')) {
      $edit_jobs->[0]{'source'} = $source;
    }
  }
  $edit_jobs = @$edit_jobs ? $fieldset2->add_hidden({ 'name' => 'edit_jobs', 'value' => $self->jsonify($edit_jobs) }) : '';

  # Current species as hidden field
  my $species_input = $fieldset2->add_hidden({'name' => 'default_species', 'value' => $species});

  # Buttons in a new fieldset
  my $buttons_fieldset = $self->add_buttons_fieldset($fieldset2->form, {'reset' => 'Clear', 'cancel' => 'Close form'});

  # Add the render-time changes to the fields
  $fieldset2->prepare_to_render;

  # Regexp to replace all placeholders from cached form
  $form =~ s/SPECIES_INPUT/$species_input->render/e;
  $form =~ s/EDIT_JOB/$edit_jobs && $edit_jobs->render/e;
  $form =~ s/BUTTONS_FIELDSET/$buttons_fieldset->render/e;

  return sprintf('<div class="hidden _tool_new"><p><a class="button _change_location" href="%s">New Search</a></p></div><div class="hidden _tool_form_div"><h2>Create new ticket:</h2><input type="hidden" class="panel_type" value="BlastForm" />%s%s</div>',
    $hub->url({'function' => ''}),
    $self->alt_assembly_info($species, 'BLAST/BLAT', 'Blast'),
    $form
  );
}

sub get_form_node {
  ## Gets the form tree node
  ## @return EnsEMBL::Web::Form object
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $form            = $self->new_tool_form('Blast', {'class' => 'blast-form'});
  my $fieldset        = $form->fieldset;
  my $form_params     = $object->get_blast_form_options;
  my $options         = delete $form_params->{'options'};
  my $combinations    = delete $form_params->{'combinations'};
  my $missing_sources = delete $form_params->{'missing_sources'};

  # Placeholders for previous job json and species hidden input
  $form->append_child('text', 'EDIT_JOB');
  $form->append_child('text', 'SPECIES_INPUT');

  $fieldset->add_hidden({
    'name'            => 'valid_combinations',
    'value'           => $combinations
  });

  $fieldset->add_hidden({
    'name'            => 'missing_sources',
    'value'           => $missing_sources
  });

  $fieldset->add_hidden({
    'name'            => 'max_sequence_length',
    'value'           => MAX_SEQUENCE_LENGTH,
  });

  $fieldset->add_hidden({
    'name'            => 'dna_threshold_percent',
    'value'           => DNA_THRESHOLD_PERCENT,
  });

  $fieldset->add_hidden({
    'name'            => 'max_number_sequences',
    'value'           => MAX_NUM_SEQUENCES,
  });

  $fieldset->add_hidden({
    'name'            => 'read_file_url',
    'value'           => $hub->url('Json', {'function' => 'read_file'})
  });

  $fieldset->add_hidden({
    'name'            => 'fetch_sequence_url',
    'value'           => $hub->url('Json', {'function' => 'fetch_sequence'})
  });

  my $query_seq_field = $fieldset->add_field({
    'label'           => 'Sequence data',
    'field_class'     => '_adjustable_height',
    'helptip'         => 'Enter sequence as plain text or in FASTA format, or enter a sequence ID or accession from EnsEMBL, EMBL, UniProt or RefSeq',
    'elements'        => [{
      'type'            => 'div',  # container used by js for adding sequence divs
      'element_class'   => '_sequence js_sequence_wrapper hidden',
    }, {
      'type'            => 'div',  # other sequence input elements will get wrapped in this one later
      'element_class'   => '_sequence_field',
      'children'        => [{'node_name' => 'div', 'class' => 'query_sequence_wrapper'}]
    }, {
      'type'            => 'text',
      'value'           =>  sprintf('Maximum of %s sequences (type in plain text, FASTA or sequence ID)', MAX_NUM_SEQUENCES),
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

  my $search_against_field; 
  if ($hub->species_defs->ENSEMBL_SERVERNAME eq 'grch37.ensembl.org') {
    $search_against_field = $fieldset->add_field({
      'label'           => 'Search against',
      'type'            => 'NoEdit',
      'value'           => 'Human (Homo sapiens)',
    });
    $fieldset->add_hidden({
      'name'            => 'species',
      'value'           => 'Homo_sapiens',
    });
  }
  else {
    $search_against_field = $fieldset->add_field({
      'label'           => 'Search against',
      'field_class'     => '_adjustable_height',
      'type'            => 'speciesdropdown',
      'name'            => 'species',
      'values'          => delete $options->{'species'},
      'multiple'        => 1,
      'wrapper_class'   => '_species_dropdown',
      'filter_text'     => 'Type in to add a species&#8230;',
      'filter_no_match' => 'No matching species found'
    });
  }

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
    $fieldset->add_hidden({'name' => 'sensitivity_configs', 'value' => $self->jsonify($all_config_sets)});
  }


  $fieldset->add_field({
    'label'           => 'Description (optional):',
    'type'            => 'string',
    'name'            => 'description',
    'size'            => '160',
  });

  # Advanced config options
  $form->add_fieldset('Configuration options');

  my $config_fields   = CONFIGURATION_FIELDS;
  my $config_defaults = CONFIGURATION_DEFAULTS;

  my @search_types    = map $_->{'value'}, @{$options->{'search_type'}};
  my %stt_classes     = map {$_ => "_stt_$_"} @search_types; # class names for selectToToggle

  while (my ($config_type, $config_field_group) = splice @$config_fields, 0, 2) {
    my $config_title    = ucfirst "$config_type options:" =~ s/_/ /gr;
    my $config_wrapper  = $form->append_child('div', {
      'class'       => 'extra_configs_wrapper',
      'children'    => [{
        'node_name'   => 'div',
        'class'       => 'extra_configs_button',
        'children'    => [{
          'node_name'   => 'a',
          'rel'         => "_blast_configs_$config_type",
          'class'       => [qw(_slide_toggle toggle set_cookie closed)],
          'href'        => "#Configuration_$config_type",
          'inner_HTML'  => $config_title
        }]
      }, {
        'node_name'   => 'div',
        'class'       => "extra_configs _blast_configs_$config_type toggleable hidden"
      }]
    });

    my $fieldset        = $config_wrapper->last_child->append_child($form->add_fieldset); # moving it from the form to the config div
    my %wrapper_class;

    while (my ($element_name, $element_params) = splice @$config_field_group, 0, 2) {

      my $field_params = { map { exists $element_params->{$_} ? ($_ => delete $element_params->{$_}) : () } qw(field_class label helptip notes head_notes inline) };
      $field_params->{'elements'} = [];

      my %field_class;

      ## add one element for each with its own default value for each valid search type
      foreach my $search_type_value (@search_types) {
        for ($search_type_value, 'all') {
          if (exists $config_defaults->{$_}{$element_name}) {
            my $element_class = $stt_classes{$search_type_value};
            push @{$field_params->{'elements'}}, {
              %{$self->deepcopy($element_params)},
              'name'          => "${search_type_value}__${element_name}",
              'value'         => $config_defaults->{$_}{$element_name},
              'element_class' => $element_class
            };
            $field_class{$element_class}    = 1; # adding same class to the field makes sure the field is only visible if at least one of the elements is visible
            $wrapper_class{$element_class}  = 1; # adding same class to the config wrapper div makes sure the div is only visible if at least one of the field is visible
            last;
          }
        }
      }

      my $field = $fieldset->add_field($field_params);
      $field->set_attribute('class', [ keys %field_class ]) unless keys %field_class == keys %stt_classes; # if all classes are there, this field is actually never hidden.
    }

    $config_wrapper->set_attribute('class', [ keys %wrapper_class ]) unless scalar keys %wrapper_class == scalar keys %stt_classes; # if all classes are there, this wrapper div is actually never hidden.
  }

  # Placeholder for Run/Close buttons
  $form->append_child('text', 'BUTTONS_FIELDSET');

  return $form;
}

1;
