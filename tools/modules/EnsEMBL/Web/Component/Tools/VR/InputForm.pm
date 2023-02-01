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

package EnsEMBL::Web::Component::Tools::VR::InputForm;

use strict;
use warnings;

use EnsEMBL::Web::VRConstants qw(INPUT_FORMATS);
use HTML::Entities qw(encode_entities);

use parent qw(
  EnsEMBL::Web::Component::Tools::VR
  EnsEMBL::Web::Component::Tools::InputForm
);

sub form_header_info {
  ## Abstract method implementation
  my $self = shift;

  return $self->tool_header({'reset' => 'Clear form', 'cancel' => 'Close'});
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $sd              = $hub->species_defs;
  my $species         = $object->species_list;
  my $form            = $self->new_tool_form;
  my $fd              = $object->get_form_details;
  my $input_formats   = INPUT_FORMATS;
  my $input_fieldset  = $form->add_fieldset({'no_required_notes' => 1});
  my $current_species = $self->current_species;
  my $msg             = $self->species_specific_info($self->current_species, 'VR', 'VR', 1);

  my ($current_species_data)  = grep { $_->{value} eq $current_species } @$species;
  my @available_input_formats = grep { $current_species_data->{example}->{$_->{value}} } @$input_formats;
  my $species_form_data;

  foreach (@$species) {

    # To send classes and other info needed for form data
    $species_form_data->{$_->{'value'}}->{'class'} = join (' ', '_stt', '_sttmulti',
                                    $_->{'variation'}             ? '_stt__var'   : '_stt__novar'
                                  );
    $species_form_data->{$_->{'value'}}->{'img_url'} = $_->{'img_url'};
    $species_form_data->{$_->{'value'}}->{'display_name'} = $_->{'caption'};
    $species_form_data->{$_->{'value'}}->{'vep_assembly'} = $_->{'assembly'};
  }

  # New species selector
  # Pass the favourite species as default species. This will be used if action = Multi.
  # Else default species is set in javascript.
  my $default_species = $hub->get_favourite_species->[0];

  my $list            = '<li>' . $self->object->getSpeciesDisplayHtml($current_species) . '</li>';
  my $checkboxes      = sprintf('<input type="checkbox" name="species" value="%s" class="%s" checked>%s', $current_species, $species_form_data->{$current_species}->{'class'}, $current_species);

  my $modal_uri       = $hub->url('MultiSelector', {
                          qw(type Tools action VEP function TaxonSelector),
                          s => $default_species,
                          multiselect => 0,
                          referer_type => $hub->type,
                          referer_action => $hub->action
                        });

  my $species_select  = $form->append_child('div', {
    'class'       => 'js_panel taxon_selector_form ff-right _sdd',
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
      'value'     => '0',
      'type'      => 'hidden',
    }, {
      'node_name' => 'div',
      'class'     => 'list-wrapper',
      'children'  => [{
        'node_name'  => 'ul',
        'class'      => 'list',
        'inner_HTML' => "$list"
      }, {
        'node_name'   => 'div',
        'inner_HTML'  => 'Assembly: <span> </span>',
        'class'       => '_vep_assembly italic'
      }, {
        'node_name' => 'div',
        'class'     => 'links',
        'children'     => [{
          'node_name'  => 'a',
          'class'      => 'modal_link data add_species_link',
          'href'       => $modal_uri,
          'inner_HTML' => 'Change species'
        }, {
          'node_name'   => 'div',
          'inner_HTML'  => $msg,
          'class'       => 'assembly_msg italic'
        }]
      }]
    }, {
      'node_name'  => 'div',
      'class'         => 'checkboxes',
      'inner_HTML' => "$checkboxes"
    }]
  });

  my $ss_field = $input_fieldset->add_field({
    'label'           => 'Species',
    'field_class'     => '_adjustable_height',
  });
  $ss_field->append_child($species_select);

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this job (optional)'
  });

  $input_fieldset->add_field({
    'label'         => 'Input data',
    'helptip'       => 'Variant ID, HGVS notation or genomic SPDI notation. (We recommend small sets of data, a maximum of 1000 variants is advised)',
    'elements'      => [
      {
        'type'          => 'noedit',
        'value'         => '<b>Either paste data:</b>',
        'no_input'      => 1,
        'is_html'       => 1,
      },
      {
       'type'          => 'text',
       'name'          => 'text',
       'class'         => 'vep-input',
      },
      add_example_links(\@available_input_formats),
      {
        'type'          => 'div',
        'element_class' => 'vep_left_input',
        'inline'        => 1,
        'children'      => [{
          'node_name'   => 'span',
          'class'       => '_ht ht',
          'title'       => sprintf('File uploads are limited to %sMB in size.', $sd->ENSEMBL_TOOLS_CGI_POST_MAX->{'VEP'} / (1024 * 1024)),
          'inner_HTML'  => '<b>Or upload file:</b>'
        }]
      },
      {
        'type'            => 'file',
        'name'            => 'file',
      }]
  });

  $input_fieldset->add_field({
    'type'          => 'checklist',
    'label'         => 'Results',
    'field_class'   => [qw(_stt_yes _stt_allele)],
    'values'        => [{
      'name'          => "spdi",
      'caption'       => $fd->{spdi}->{label},
      'helptip'       => $fd->{spdi}->{helptip},
      'value'         => 'yes',
      'checked'       => 1
    }, {
      'name'          => "hgvsg",
      'caption'       => $fd->{hgvsg}->{label},
      'helptip'       => $fd->{hgvsg}->{helptip},
      'value'         => 'yes',
      'checked'       => 1
    }, {
      'name'          => "hgvsc",
      'caption'       => $fd->{hgvsc}->{label},
      'helptip'       => $fd->{hgvsc}->{helptip},
      'value'         => 'yes',
      'checked'       => 1
    }, {
      'name'          => "hgvsp",
      'caption'       => $fd->{hgvsp}->{label},
      'helptip'       => $fd->{hgvsp}->{helptip},
      'value'         => 'yes',
      'checked'       => 1
    }, {
      'name'          => "vcf_string",
      'caption'       => $fd->{vcf_string}->{label},
      'helptip'       => $fd->{vcf_string}->{helptip},
      'value'         => 'yes',
      'checked'       => 1
    }, {
      'name'          => "id",
      'caption'       => $fd->{id}->{label},
      'helptip'       => $fd->{id}->{helptip},
      'value'         => 'yes',
      'checked'       => 1
    }, {
      'name'          => "var_synonyms",
      'caption'       => $fd->{var_synonyms}->{label},
      'helptip'       => $fd->{var_synonyms}->{helptip},
      'value'         => 'yes',
      'checked'       => 0
    }]
  });

  # Add Mane Select option separately with a different classname for ease of toggling
  $input_fieldset->add_field({
    'type'        => 'checklist',
    'field_class' => [qw(_stt_yes _stt_allele _stt_mane_select)],
    'name'        => 'mane_select',
    'values'      => [{
      'caption'     => $fd->{mane_select}->{label},
      'helptip'     => $fd->{mane_select}->{helptip},
      'value'       => 'yes',
      'checked'     => 0
    }]
  });

  # Run button
  $self->add_buttons_fieldset($form);

  return $form;
}

sub add_example_links {
  my $input_formats = shift;

  if ($#$input_formats >= 0) {
    return {
      'type'    => 'noedit',
      'noinput' => 1,
      'is_html' => 1,
      'caption' => sprintf('<span class="small"><b>Examples:&nbsp;</b>%s</span>',
        join(', ', (map { sprintf('<a href="#" class="_example_input" rel="%s">%s</a>', $_->{'value'}, $_->{'caption'}) } @$input_formats ))
      )
    }
  }
  return;
}
sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## @override
  return 'VRForm';
}

sub js_params {
  ## @override
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $species = $object->species_list;
  my $params  = $self->SUPER::js_params(@_);

  # example data for each species
  $params->{'example_data'} = { map { $_->{'value'} => delete $_->{'example'} } @$species };

  return $params;
}

1;
