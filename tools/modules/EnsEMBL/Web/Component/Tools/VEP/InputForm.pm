=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::VEP::InputForm;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::VEPConstants qw(INPUT_FORMATS CONFIG_SECTIONS);

use parent qw(
  EnsEMBL::Web::Component::Tools::VEP
  EnsEMBL::Web::Component::Tools::InputForm
);

sub form_header_info {
  ## Abstract method implementation
  my $self = shift;

  return $self->species_specific_info($self->current_species, 'VEP', 'VEP');
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $sd              = $hub->species_defs;
  my $species         = $object->species_list;
  my $form            = $self->new_tool_form({'class' => 'vep-form'});
  my $fd              = $object->get_form_details;
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
        'class'         => [  #selectToToggle classes for JavaScript
          '_stt', '_sttmulti',
          $_->{'variation'}             ? '_stt__var'   : '_stt__novar',
          $_->{'refseq'}                ? '_stt__rfq'   : (),
          $_->{'variation'}{'POLYPHEN'} ? '_stt__pphn'  : (),
          $_->{'variation'}{'SIFT'}     ? '_stt__sift'  : ()
        ]
      }, @$species ]
    }, {
      'type'          => 'noedit',
      'value'         => 'Assembly: '. join('', map { sprintf '<span class="_stt_%s _vep_assembly" rel="%s">%s</span>', $_->{'value'}, $_->{'assembly'}, $_->{'assembly'} } @$species),
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
    'elements'      => [{
      'type'          => 'text',
      'name'          => 'text',
      'class'         => 'vep-input',
    }, {
      'type'          => 'noedit',
      'noinput'       => 1,
      'is_html'       => 1,
      'caption'       => sprintf('<span class="small"><b>Examples:&nbsp;</b>%s</span>',
        join(', ', (map { sprintf('<a href="#" class="_example_input" rel="%s">%s</a>', $_->{'value'}, $_->{'caption'}) } @$input_formats))
      )
    }, {
      'type'          => 'button',
      'name'          => 'preview',
      'class'         => 'hidden quick-vep-button',
      'value'         => 'Run instant VEP for current line &rsaquo;',
    }]
  });

  $input_fieldset->add_field({
    'type'          => 'file',
    'name'          => 'file',
    'label'         => 'Or upload file',
    'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $sd->ENSEMBL_TOOLS_CGI_POST_MAX->{'VEP'} / (1024 * 1024))
  });

  $input_fieldset->add_field({
    'type'          => 'url',
    'name'          => 'url',
    'label'         => 'Or provide file URL',
    'size'          => 30,
    'class'         => 'url'
  });

  # This field is shown only for the species having refseq data
  if (first { $_->{'refseq'} } @$species) {
    $input_fieldset->add_field({
      'field_class'   => '_stt_rfq',
      'type'          => 'radiolist',
      'name'          => 'core_type',
      'label'         => $fd->{core_type}->{label},
      'helptip'       => $fd->{core_type}->{helptip},
      'value'         => 'core',
      'class'         => '_stt',
      'values'        => $fd->{core_type}->{values}
    });

    $input_fieldset->add_field({
      'field_class'   => '_stt_rfq _stt_merged _stt_refseq',
      'type'    => 'checkbox',
      'name'    => "all_refseq",
      'label'   => $fd->{all_refseq}->{label},
      'helptip' => $fd->{all_refseq}->{helptip},
      'value'   => 'yes',
      'checked' => 0
    });
  }

  ## Output options header
  $form->add_fieldset({'no_required_notes' => 1});

  ### Advanced config options
  my $sections = CONFIG_SECTIONS;
  foreach my $section (@$sections) {

    $self->togglable_fieldsets($form, {
      'title' => $section->{'title'},
      'desc'  => $section->{'caption'}
    }, $self->can('_build_'.$section->{'id'})->($self, $form));
  }

  # Run/Close buttons
  $self->add_buttons_fieldset($form, {'reset' => 'Clear', 'cancel' => 'Close form'});

  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## @override
  return 'VEPForm';
}

sub js_params {
  ## @override
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $species = $object->species_list;
  my $params  = $self->SUPER::js_params(@_);

  # consequences data to be used for VEP preview
  $params->{'consequences_data'} = $object->get_consequences_data;

  # example data for each species
  $params->{'example_data'} = { map { $_->{'value'} => delete $_->{'example'} } @$species };

  # REST server address for VEP preview
  $params->{'rest_server_url'} = $hub->species_defs->ENSEMBL_REST_URL;

  return $params;
}

sub _build_filters {
  my ($self, $form) = @_;

  my $object    = $self->object;
  my $fd        = $object->get_form_details;
  my $species   = $object->species_list;
  my $fieldset  = $form->add_fieldset({'legend' => 'Filters', 'no_required_notes' => 1});

  if (first { $_->{'value'} eq 'Homo_sapiens' } @$species) {

    $fieldset->add_field({
      'field_class'   => '_stt_Homo_sapiens',
      'label'         => $fd->{frequency}->{label},
      'helptip'       => $fd->{frequency}->{helptip},
      'inline'        => 1,
      'elements'      => [{
        'type'          => 'radiolist',
        'name'          => 'frequency',
        'value'         => 'no',
        'class'         => '_stt',
        'values'        => $fd->{frequency}->{values},
      }, {
        'element_class' => '_stt_advanced',
        'type'          => 'dropdown',
        'name'          => 'freq_filter',
        'value'         => 'exclude',
        'values'        => $fd->{freq_filter}->{values}
      }, {
        'element_class' => '_stt_advanced',
        'type'          => 'dropdown',
        'name'          => 'freq_gt_lt',
        'value'         => 'gt',
        'values'        => $fd->{freq_gt_lt}->{values}
      }, {
        'element_class' => '_stt_advanced',
        'type'          => 'string',
        'name'          => 'freq_freq',
        'value'         => '0.01',
        'max'           => 1,
      }, {
        'element_class' => '_stt_advanced',
        'type'          => 'dropdown',
        'name'          => 'freq_pop',
        'value'         => '1kg_all',
        'values'        => $fd->{freq_pop}->{values}
      }]
    });
  }

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => "coding_only",
    'label'   => $fd->{coding_only}->{label},
    'helptip' => $fd->{coding_only}->{helptip},
    'value'   => 'yes',
    'checked' => 0
  });

  $fieldset->add_field({
    'type'    => 'dropdown',
    'name'    => 'summary',
    'label'   => 'Restrict results',
    'helptip' => 'Restrict results by severity of consequence; note that consequence ranks are determined subjectively by Ensembl',
    'value'   => 'no',
    'notes'   => '<b>NB:</b> Restricting results may exclude biologically important data!',
    'values'  => [
      { 'value' => 'no',          'caption' => 'Show all results' },
      { 'value' => 'pick',        'caption' => 'Show one selected consequence per variant'},
      { 'value' => 'pick_allele', 'caption' => 'Show one selected consequence per variant allele'},
      { 'value' => 'per_gene',    'caption' => 'Show one selected consequence per gene' },
      { 'value' => 'summary',     'caption' => 'Show only list of consequences per variant' },
      { 'value' => 'most_severe', 'caption' => 'Show most severe consequence per variant' },
    ]
  });

  return $fieldset;
}

sub _build_identifiers {
  my ($self, $form) = @_;

  my $hub       = $self->hub;
  my $object    = $self->object;
  my $species   = $object->species_list;
  my $fd        = $object->get_form_details;

  my @fieldsets;

  ## IDENTIFIERS
  my $current_section = 'Identifiers';
  my $fieldset        = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1});

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'symbol',
    'label'       => $fd->{symbol}->{label},
    'helptip'     => $fd->{symbol}->{helptip},
    'value'       => 'yes',
    'checked'     => 1
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_merged _stt_gencode_basic',
    'type'        => 'checkbox',
    'name'        => 'ccds',
    'label'       => $fd->{ccds}->{label},
    'helptip'     => $fd->{ccds}->{helptip},
    'value'       => 'yes',
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'protein',
    'label'       => $fd->{protein}->{label},
    'helptip'     => $fd->{protein}->{helptip},
    'value'       => 'yes'
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'uniprot',
    'label'       => $fd->{uniprot}->{label},
    'helptip'     => $fd->{uniprot}->{helptip},
    'value'       => 'yes'
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'hgvs',
    'label'       => $fd->{hgvs}->{label},
    'helptip'     => $fd->{hgvs}->{helptip},
    'value'       => 'yes'
  });

  $self->_end_section(\@fieldsets, $fieldset, $current_section);

  ## FREQUENCY DATA
  # only for the species that have variants
  $current_section = 'Frequency data';
  if ((first { $_->{'variation'} } @$species) || scalar @{$self->_get_plugins_by_section($current_section)}) {
    $fieldset = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1});

    $fieldset->add_field({
      'field_class' => '_stt_var',
      'label'       => $fd->{check_existing}->{label},
      'helptip'     => $fd->{check_existing}->{helptip},
      'type'        => 'dropdown',
      'name'        => "check_existing",
      'value'       => 'yes',
      'class'       => '_stt',
      'values'      => $fd->{check_existing}->{values}
    });

    $fieldset->append_child('div', {
      'class'         => '_stt_Homo_sapiens',
      'children'      => [$fieldset->add_field({
        'type'          => 'checklist',
        'label'         => 'Frequency data for co-located variants',
        'field_class'   => [qw(_stt_yes _stt_allele)],
        'values'        => [{
          'name'          => "af",
          'caption'       => $fd->{af}->{label},
          'helptip'       => $fd->{af}->{helptip},
          'value'         => 'yes',
          'checked'       => 1
        }, {
          'name'          => "af_1kg",
          'caption'       => $fd->{af_1kg}->{label},
          'helptip'       => $fd->{af_1kg}->{helptip},
          'value'         => 'yes',
          'checked'       => 0
        }, {
          'name'          => "af_esp",
          'caption'       => $fd->{af_esp}->{label},
          'helptip'       => $fd->{af_esp}->{helptip},
          'value'         => 'yes',
          'checked'       => 0
        }, {
          'name'          => "af_gnomad",
          'caption'       => $fd->{af_gnomad}->{label},
          'helptip'       => $fd->{af_gnomad}->{helptip},
          'value'         => 'yes',
          'checked'       => 0
        }]
      }), $fieldset->add_field({
        'type' => 'checkbox',
        'name' => 'pubmed',
        'label' => $fd->{pubmed}->{label},
        'helptip' => $fd->{pubmed}->{helptip},
        'value' => 'yes',
        'checked' => 1,
        'field_class'   => [qw(_stt_yes _stt_allele)],
      }), $fieldset->add_field({
        'type' => 'checkbox',
        'name' => 'failed',
        'label' => $fd->{failed}->{label},
        'helptip' => $fd->{failed}->{helptip},
        'value' => 1,
        'checked' => 0,
        'field_class'   => [qw(_stt_yes _stt_allele)],
      })]
    });

    $self->_end_section(\@fieldsets, $fieldset, $current_section);
  }

  $self->_plugin_footer($fieldset) if $self->_have_plugins;

  return @fieldsets;
}

sub _build_extra {
  my ($self, $form) = @_;

  my $hub       = $self->hub;
  my $object    = $self->object;
  my $sd        = $hub->species_defs;
  my $species   = $object->species_list;
  my $fd        = $object->get_form_details;

  my @fieldsets;

  ## MISCELLANEOUS SECTION
  my $current_section = 'Miscellaneous';
  my $fieldset  = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1});

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'biotype',
    'label'       => $fd->{biotype}->{label},
    'helptip'     => $fd->{biotype}->{helptip},
    'value'       => 'yes',
    'checked'     => 1
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'domains',
    'label'       => $fd->{domains}->{label},
    'helptip'     => $fd->{domains}->{helptip},
    'value'       => 'yes',
    'checked'     => 0,
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'numbers',
    'label'       => $fd->{numbers}->{label},
    'helptip'     => $fd->{numbers}->{helptip},
    'value'       => 'yes',
    'checked'     => 0
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'tsl',
    'label'       => $fd->{tsl}->{label},
    'helptip'     => $fd->{tsl}->{helptip},
    'value'       => 'yes',
    'checked'     => 1,
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'appris',
    'label'       => $fd->{appris}->{label},
    'helptip'     => $fd->{appris}->{helptip},
    'value'       => 'yes',
    'checked'     => 1,
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'canonical',
    'label'       => $fd->{canonical}->{label},
    'helptip'     => $fd->{canonical}->{helptip},
    'value'       => 'yes',
    'checked'     => 0,
  });

  $fieldset->add_field({
    'type'        => 'string',
    'name'        => 'distance',
    'label'       => $fd->{distance}->{label},
    'helptip'     => $fd->{distance}->{helptip},
    'value'       => $fd->{distance}->{value},
    'checked'     => 0,
  });

  $self->_end_section(\@fieldsets, $fieldset, $current_section);


  ## PATHOGENICITY PREDICTIONS
  $current_section = 'Pathogenicity predictions';
  my $have_sift = first { $_->{'variation'}{'SIFT'} } @$species;
  my $have_polyphen = first { $_->{'variation'}{'POLYPHEN'} } @$species;
  my $have_plugins = scalar @{$self->_get_plugins_by_section($current_section)};
  $fieldset = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1, 'class' => ['_stt_sift','_stt_pphn']}) if $have_sift or $have_polyphen or $have_plugins;

  # sift
  if ($have_sift) {

    $fieldset->add_field({
      'field_class' => '_stt_sift',
      'type'        => 'dropdown',
      'label'       => $fd->{sift}->{label},
      'helptip'     => $fd->{sift}->{helptip},
      'name'        => 'sift',
      'value'       => 'b',
      'values'      => $fd->{sift}->{values},
    });
  }

  # polyphen
  if ($have_polyphen) {

    $fieldset->add_field({
      'field_class' => '_stt_pphn',
      'type'        => 'dropdown',
      'label'       => $fd->{polyphen}->{label},
      'helptip'     => $fd->{polyphen}->{helptip},
      'name'        => 'polyphen',
      'value'       => 'b',
      'values'      => $fd->{polyphen}->{values},
    });
  }

  $self->_end_section(\@fieldsets, $fieldset, $current_section);


  ## REGULATORY DATA
  $current_section = 'Regulatory data';

  $have_plugins = scalar @{$self->_get_plugins_by_section($current_section)};

  my @regu_species = map { $_->{'value'} } grep {$hub->get_adaptor('get_EpigenomeAdaptor', 'funcgen', $_->{'value'})} grep {$_->{'regulatory'}} @$species;
  $fieldset = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1}) if scalar @regu_species or $have_plugins;

  for (@regu_species) {
    # get available cell types
    my $regulatory_build_adaptor = $hub->get_adaptor('get_RegulatoryBuildAdaptor', 'funcgen', $_);
    my $regulatory_build = $regulatory_build_adaptor->fetch_current_regulatory_build;
    my $cell_types = [
      sort
      map {{ value => $_->production_name, caption => $_->display_label }}
      @{$regulatory_build->get_all_Epigenomes}
    ];

    $fieldset->add_field({
      'field_class'   => "_stt_$_",
      'label'         => $fd->{regulatory}->{label},
      'helptip'       => $fd->{regulatory}->{helptip},
      'elements'      => [{
        'type'          => 'dropdown',
        'name'          => "regulatory_$_",
        'class'         => '_stt',
        'value'         => 'reg',
        'values'        => [
          { 'value'       => 'no',   'caption' => 'No'                                                      },
          { 'value'       => 'reg',  'caption' => 'Yes'                                                     },
          { 'value'       => 'cell', 'caption' => 'Yes and limit by cell type', 'class' => "_stt__cell_$_"  }
        ]
      }, {
        'type'          => 'noedit',
        'caption'       => $fd->{cell_type}->{helptip},
        'no_input'      => 1,
        'element_class' => "_stt_cell_$_"
      }, {
        'element_class' => "_stt_cell_$_",
        'type'          => 'dropdown',
        'multiple'      => 1,
        'label'         => $fd->{cell_type}->{label},
        'name'          => "cell_type_$_",
        'values'        => [ map { 'value' => $_->{value}, 'caption' => $_->{caption} }, @$cell_types ]
      }]
    });
  }

  $self->_end_section(\@fieldsets, $fieldset, $current_section);


  ## ANY OTHER SECTIONS CONFIGURED BY PLUGINS
  foreach my $current_section(grep {!$self->{_done_sections}->{$_}} @{$self->_get_all_plugin_sections}) {
    $fieldset = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1});
    $self->_end_section(\@fieldsets, $fieldset, $current_section);
  }

  $self->_plugin_footer($fieldset) if $self->_have_plugins;

  return @fieldsets;
}

sub _end_section {
  my ($self, $fieldsets, $fieldset, $section) = @_;

  push @$fieldsets, $fieldset;

  $self->_add_plugins($fieldset, $section) if @{$self->_get_plugins_by_section($section)};
  $self->{_done_sections}->{$section} = 1;
}

sub _have_plugins {
  my $self = shift;

  if(!exists($self->{_have_plugins})) {
    my $sd  = $self->hub->species_defs;
    if(my $pl = $sd->multi_val('ENSEMBL_VEP_PLUGIN_CONFIG')) {
      $self->{_have_plugins} = $pl && $pl->{plugins} ? 1 : 0;
    }
    else {
      $self->{_have_plugins} = 0;
    }
  }

  return $self->{_have_plugins};
}

sub _get_all_plugin_sections {
  my $self = shift;
  return [] unless $self->_have_plugins();
  my $sd  = $self->hub->species_defs;
  my $pl  = $sd->multi_val('ENSEMBL_VEP_PLUGIN_CONFIG');

  my @list = grep {$_} map {$_->{section} || ''} grep {$_->{available}} @{$pl->{plugins}};
  my %seen;
  my @return = ();

  foreach my $s(@list) {
    push @return, $s unless $seen{$s};
    $seen{$s} = 1;
  }

  return \@return;
}

sub _get_plugins_by_section {
  my ($self, $section) = @_;

  return [] unless $self->_have_plugins();

  if(!exists($self->{_plugins_by_section}) || !exists($self->{_plugins_by_section}->{$section})) {
    my $sd  = $self->hub->species_defs;
    my $pl  = $sd->multi_val('ENSEMBL_VEP_PLUGIN_CONFIG');

    my @matched;
    if($section eq 'Miscellaneous') {
      @matched = grep {$_->{available} && !defined($_->{section})} @{$pl->{plugins}};
    }
    else {
      @matched = grep {$_->{available} && defined($_->{section}) && $_->{section} eq $section} @{$pl->{plugins}};
    }

    $self->{_plugins_by_section}->{$section} = \@matched;
  }

  return $self->{_plugins_by_section}->{$section};
}

sub _add_plugins {
  my ($self, $fieldset, $section_name) = @_;

  my ($ac_values, %required);
  my $species = $self->object->species_list;
  my $sd      = $self->hub->species_defs;
  my $pl      = $sd->multi_val('ENSEMBL_VEP_PLUGIN_CONFIG');

  foreach my $plugin(@{$self->_get_plugins_by_section($section_name)}) {
    my $pl_key = $plugin->{key};

    # sort out which species to make this available for
    # the config carries the species name and assembly
    # the interface will only have one assembly per species, but need to check they match
    # my $field_class = [];
    # my $pl_species = $plugin->{species};
    #
    # if($pl_species && ref($pl_species) eq 'ARRAY') {
    #   foreach my $sp_hash(@$pl_species) {
    #     push @$field_class,
    #       map {"_stt_".$_}
    #       map {$_->{assembly} eq $sp_hash->{assembly} ? $_->{value} : $_->{value}.'_'.$_->{assembly}}
    #       grep {$_->{value} eq ucfirst($sp_hash->{name})}
    #       @$species;
    #   }
    # }

    my $field_class = (!$plugin->{species} || $plugin->{species} eq '*') ? [] : [map {"_stt_".ucfirst($_)} @{$plugin->{species} || []}];

    if($plugin->{form}) {

      $fieldset->add_field({
        'class'       => "_stt plugin_enable",
        'field_class' => $field_class,
        'type'        => 'radiolist',
        'helptip'     => $plugin->{helptip},
        'name'        => 'plugin_'.$pl_key,
        'label'       => ($plugin->{label} || $pl_key).'<sup style="color:grey">(p)</sup>',
        'value'       => $plugin->{enabled} ? 'plugin_'.$pl_key : 'no',
        'values'      => [
          { 'value' => 'no', 'caption' => 'Disabled' },
          { 'value' => 'plugin_'.$pl_key, 'caption' => 'Enabled' },
        ],
      });

      foreach my $el(@{$plugin->{form}}) {
        $el->{field_class} = '_stt_plugin_'.$pl_key;
        $el->{label}     ||= $el->{name};
        $el->{value}       = exists($el->{value}) ? $el->{value} : $el->{name};
        $el->{name}        = 'plugin_'.$pl_key.'_'.$el->{name};

        # get autocomplete values
        if($el->{class} && $el->{values} && $el->{class} =~ /autocomplete/) {
          $ac_values->{$el->{name}} = $el->{values};
        }

        # required?
        if(delete $el->{required}) {
          push @{$required{'plugin_'.$pl_key}}, $el->{name};
        }

        $fieldset->add_field($el);
      }
    }

    else {
      $fieldset->add_field({
        'class'       => "_stt plugin_enable",
        'field_class' => $field_class,
        'type'        => 'checkbox',
        'helptip'     => $plugin->{helptip},
        'name'        => 'plugin_'.$pl_key,
        'label'       => ($plugin->{label} || $pl_key).'<sup style="color:grey">(p)</sup>',
        'value'       => 'plugin_'.$pl_key,
        'checked'     => $plugin->{enabled} ? 1 : 0,
      });
    }
  }

  # add autocomplete values as a js_param hidden field
  if($ac_values) {
    my $ac_json = encode_entities($self->jsonify($ac_values));

    $fieldset->add_hidden({
      class => "js_param",
      name => "plugin_auto_values",
      value => $ac_json
    });
  }

  # add required params
  if(scalar keys %required) {
    $fieldset->add_hidden({
      name => "required_params",
      value => join(';', map {$_.'='.join(',', @{$required{$_}})} keys %required)
    });
  }
}

sub _plugin_footer {
  my ($self, $fieldset) = @_;

  $fieldset->append_child('div', {
    'children' => [{
      'node_name'   => 'p',
      'class'       => 'small',
      'inner_HTML'  => '<span style="color:grey">(p)</span> = functionality from <a target="_blank" href="/info/docs/tools/vep/script/vep_plugins.html">VEP plugin</a>'
    }]
  });
}

1;
