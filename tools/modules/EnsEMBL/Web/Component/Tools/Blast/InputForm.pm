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

package EnsEMBL::Web::Component::Tools::Blast::InputForm;

use strict;
use warnings;

use EnsEMBL::Web::BlastConstants;

use base qw(EnsEMBL::Web::Component::Tools::Blast);

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  $self->ajaxable('post') if $self->hub->param('query_sequence');
}

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $dom           = $self->dom;
  my $sd            = $hub->species_defs;
  my $object        = $self->object;
  my $form_params   = $object->get_blast_form_params;
  my $fields        = delete $form_params->{'fields'};
  my $combinations  = delete $form_params->{'combinations'};
  my $selected      = delete $form_params->{'selected'};
  my $all_species   = delete $form_params->{'species'};
  my $existing_seq  = $hub->param('query_sequence');
  my $edit_jobs     = $hub->param('edit') && ($object->get_requested_job || $object->get_requested_ticket);
     $edit_jobs     = $edit_jobs ? ref($edit_jobs) =~ /Ticket/ ? $edit_jobs->job : [ $edit_jobs ] : [];
     $edit_jobs     = [ map $_->job_data->raw, @$edit_jobs ];
     $edit_jobs     = [ {'sequence' => {'seq' => $existing_seq}} ] if !@$edit_jobs && $existing_seq;

  my $form          = $self->new_form({
    'action'          => $hub->url('Json', {qw(type Tools action Blast function form_submit)}),
    'method'          => 'post',
    'class'           => 'tools_form bgcolour blast-form',
    'skip_validation' => 1
  });

  my $fieldset      = $form->add_fieldset;

  $fieldset->add_hidden({
    'name'            => 'valid_combinations',
    'value'           => $combinations
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
    'name'            => 'edit_jobs',
    'value'           => $self->jsonify($edit_jobs)
  });

  $fieldset->add_hidden({
    'name'            => 'load_ticket_url',
    'value'           => $hub->url('Json', {'function' => 'load_ticket', 'tl' => 'TICKET_NAME'})
  });

  $fieldset->add_hidden({
    'name'            => 'read_file_url',
    'value'           => $hub->url('Json', {'function' => 'read_file'})
  });

  $fieldset->add_field({
    'label'           => 'Sequence data',
    'field_class'     => '_adjustable_height',
    'elements'        => [{
      'type'            => 'iconlink',
      'caption'         => 'Add more sequences',
      'link_class'      => '_add_sequence',
      'link_icon'       => 'add',
      'element_class'   => '_sequence hidden'
    }, {
      'type'            => 'text',
      'value'           =>  sprintf('Maximum of %s sequences (type in plain text or FASTA)', MAX_NUM_SEQUENCES),
      'class'           => 'inactive query_sequence',
      'name'            => 'query_sequence',
      'element_class'   => '_sequence'
    }, {
      'type'            => 'noedit',
      'value'           => 'Or upload sequence file',
      'no_input'        => 1,
      'element_class'   => '_sequence file-upload-label'
    }, {
      'type'            => 'file',
      'name'            => 'query_file',
      'element_class'   => '_sequence'

# TODO - integrate retrieving stuff with exiting textarea box

#     }, {
#       'type'            => 'noedit',
#       'value'           => 'Or enter a sequence ID or accession',
#       'no_input'        => 1,
#       'element_class'   => '_sequence'
#     }, {
#       'type'            => 'string',
#       'name'            => 'retrieve_accession',
#       'size'            => '40',
#       'value'           => 'not enabled yet',
#       'disabled'        => 1,
#       'element_helptip' => 'EnsEMBL, EMBL, UniProt or RefSeq',
#       'element_class'   => '_sequence'
    }, {
      'type'            => 'radiolist',
      'name'            => 'query_type',
      'values'          => $fields->{'query_type'},
      'value'           => $selected->{'query_type'}
    }, {
      'type'            => 'editabletag',
      'element_class'   => 'hidden',
      'tag_class'       => '_tag_query_type _tag_child_search_type',
      'no_input'        => 1
    }]
  });

  my %requested_sepcies = map {$_->{'value'} => 1} @{$fields->{'species'}};
  my %selected_species  = map {$_ => 1} @{delete $selected->{'species'}};
  $fieldset->add_field({
    'label'           => 'Search against',
    'field_class'     => '_adjustable_height',
    'elements'        => [{
      'type'            => 'editabletag',
      'element_class'   => '_species_tags',
      'name'            => 'species',
      'tags'            => [ map {
        'tag_type'        => 'removable',
        'tag_class'       => ['species-tag', $selected_species{$_->{'value'}} ? () : 'disabled'],
        'tag_attribs'     => {'style' => sprintf(q{background-image: url('%sspecies/16/%s.png')}, $self->img_url, $_->{'value'})},
        'caption'         => $_->{'caption'},
        'value'           => $_->{'value'}
      }, @{$fields->{'species'}} ]
    }, {
      'type'            => 'iconlink',
      'element_class'   => '_add_species',
      'caption'         => 'Add/remove species',
      'link_icon'       => 'add'
    }, {
      'type'            => 'filterable',
      'multiple'        => 1,
      'element_class'   => 'hidden _species_dropdown',
      'values'          => [ sort {$a->{'caption'} cmp $b->{'caption'}} @$all_species ],
      'value'           => [ keys %requested_sepcies ],
      'filter_text'     => 'type a species name to filter&#8230;'
    }, {
      'type'            => 'iconlink',
      'caption'         => 'Done',
      'element_class'   => 'hidden _add_species_done',
      'link_icon'       => 'check'
    }, {
      'type'            => 'radiolist',
      'name'            => 'db_type',
      'class'           => '_validate_onchange',
      'values'          => $fields->{'db_type'},
      'value'           => $selected->{'db_type'}
    }, {
      'type'            => 'editabletag',
      'no_input'        => 1,
      'element_class'   => 'hidden',
      'tag_class'       => '_tag_db_type _tag_child_source _tag_child_search_type'
    }, {
      'type'            => 'dropdown',
      'name'            => 'source',
      'class'           => '_validate_onchange',
      'values'          => $fields->{'source'},
      'value'           => $selected->{'source'}
    }, {
      'type'            => 'editabletag',
      'no_input'        => 1,
      'element_class'   => 'hidden',
      'tag_class'       => '_tag_source'
    }]
  });

  $fieldset->add_field({
    'label'           => 'Search tool',
    'elements'        => [{
      'type'            => 'dropdown',
      'name'            => 'search_type',
      'class'           => '_validate_onchange _stt',
      'values'          => $fields->{'search_type'},
      'value'           => $selected->{'search_type'}
    }, {
      'type'            => 'editabletag',
      'no_input'        => 1,
      'element_class'   => 'hidden',
      'tag_class'       => '_tag_search_type'
    }]
  });

  $fieldset->add_field({
    'label'           => 'Description (optional):',
    'type'            => 'string',
    'name'            => 'description',
    'size'            => '160',
  });

  # Advanced config options
  my $config_fields   = CONFIGURATION_FIELDS;
  my $config_defaults = CONFIGURATION_DEFAULTS;
  my $config_wrapper  = $form->append_child('div', {
    'class'       => 'extra_configs_wrapper',
    'children'    => [{
      'node_name'   => 'div',
      'class'       => 'extra_configs_button',
      'children'    => [{
        'node_name'   => 'a',
        'rel'         => '_blast_configs',
        'class'       => ['toggle', 'set_cookie', 'closed'],
        'href'        => '#Configuration',
        'title'       => 'Click to see configuration options',
        'inner_HTML'  => 'Configuration Options'
      }]
    }, {
      'node_name'   => 'div',
      'class'       => [qw(extra_configs _blast_configs toggleable _adjustable_height hidden)]
    }]
  });

  my @search_types    = map $_->{'value'}, @{$fields->{'search_type'}};
  my %stt_classes     = map {$_ => "_stt_$_"} @search_types; # class names for selectToToggle

  while (my ($config_type, $config_field_group) = splice @$config_fields, 0, 2) {

    my $fieldset        = $config_wrapper->last_child->append_child($form->add_fieldset(ucfirst "$config_type options:" =~ s/_/ /gr)); # moving it from the form to the config div
    my %fieldset_class;

    while (my ($element_name, $element_params) = splice @$config_field_group, 0, 2) {

      my $label         = delete $element_params->{'label'} // '';
      my %field_class;
      my @elements;

      ## add one element for each with its own default value for each valid search type
      foreach my $search_type_value (@search_types) {
        for ($search_type_value, 'all') {
          if (exists $config_defaults->{$_}{$element_name}) {
            my $element_class = $stt_classes{$search_type_value};
            push @elements, {
              %$element_params,
              'name'          => "${search_type_value}__${element_name}",
              'value'         => $config_defaults->{$_}{$element_name},
              'element_class' => $element_class
            };
            $field_class{$element_class}    = 1; # adding same class to the field makes sure the field is only visible if at least one of the elements is visible
            $fieldset_class{$element_class} = 1; # adding same class to the fieldset makes sure the fieldset is only visible if at least one of the field is visible
            last;
          }
        }
      }

      my $field = $fieldset->add_field({ 'label' => $label, 'elements' => \@elements});
      $field->set_attribute('class', [ keys %field_class ]) unless keys %field_class == keys %stt_classes; # if all classes are there, this field is actually never hidden.

    }

    $fieldset->set_attribute('class', [ keys %fieldset_class]) unless scalar keys %fieldset_class == scalar keys %stt_classes; # if all classes are there, this fieldset is actually never hidden.

  }

  # add the 'Run' button in a new fieldset
  $form->add_fieldset->add_field({
    'type'            => 'Submit',
    'name'            => 'submit_blast',
    'value'           => 'Run &rsaquo;'
  })->elements->[-1]->append_child('a', {
    'href'            => '#Reset',
    'class'           => '_tools_form_reset left-margin',
    'inner_HTML'      => 'Reset'
  });

  return sprintf '<div><h2>%sBLAST/BLAT Search</h2><input type="hidden" class="panel_type" value="BlastForm" />%s</html>', @$edit_jobs ? '' : 'New ', $form->render;
}

1;

