=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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
use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::File::Tools;
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::VEPConstants qw(INPUT_FORMATS CONFIG_SECTIONS);
use Bio::EnsEMBL::Variation::Utils::Constants;

use parent qw(EnsEMBL::Web::Component::Tools::VEP);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $sd              = $hub->species_defs;
  my $species         = $self->_species;
  my $cache           = $hub->cache;
  my $form            = $cache ? $cache->get('VEPFORM') : undef;
  my $current_species = $hub->species;
     $current_species = $hub->get_favourite_species->[0] if $current_species =~ /multi|common/i;
  my $input_formats   = INPUT_FORMATS;

  if (!$form) {
    $form = $self->new_tool_form('VEP');

    # Placeholders for previous job json and species hidden inputs
    $form->append_child('text', 'EDIT_JOB');
    $form->append_child('text', 'SPECIES_INPUT');

    my $input_fieldset = $form->add_fieldset({'legend' => 'Input', 'class' => '_stt_input', 'no_required_notes' => 1});

    # Species dropdown list with stt classes to dynamically toggle other fields
    $input_fieldset->add_field({
      'label'         => 'Species',
      'elements'      => [{
        'type'          => 'speciesdropdown',
        'name'          => 'species',
        'value'         => $current_species,
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
      'label'         => 'Name for this data (optional)'
    });

    $input_fieldset->add_field({
      'label'         => 'Either paste data',
      'elements'      => [{
        'type'          => 'text',
        'name'          => 'text',
      }, {
        'type'          => 'noedit',
        'noinput'       => 1,
        'is_html'       => 1,
        'caption'       => sprintf('<span class="small"><b>Examples:&nbsp;</b>%s</span>',
          join(', ', map { sprintf('<a href="#" class="_example_input" rel="%s">%s</a>', $_->{'value'}, $_->{'caption'}) } @$input_formats)
        )
      }, {
        'type'          => 'button',
        'name'          => 'preview',
        'class'         => 'hidden',
        'value'         => 'Instant results for first variant &rsaquo;',
        'helptip'       => 'See a quick preview of results for data pasted above',
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

    # Placeholder for previuos files select box
    $input_fieldset->append_child('text', 'FILES_DROPDOWN');

    # This field is shown only for the species having refseq data
    if (first { $_->{'refseq'} } @$species) {
      $input_fieldset->add_field({
        'field_class'   => '_stt_rfq',
        'type'          => 'radiolist',
        'name'          => 'core_type',
        'label'         => 'Transcript database to use',
        'helptip'       =>
          '<b>Gencode basic:</b> a subset of the Ensembl transcript set; partial and other low quality transcripts are removed<br/>'.
          '<b>RefSeq:</b> aligned transcripts from NCBI RefSeq',
        'value'         => 'core',
        'class'         => '_stt',
        'values'        => [{
          'value'         => 'core',
          'caption'       => 'Ensembl transcripts'
        }, {
          'value'         => 'gencode_basic',
          'caption'       => 'Gencode basic transcripts'
        }, {
          'value'         => 'refseq',
          'caption'       => 'RefSeq transcripts'
        }, {
          'value'         => 'merged',
          'caption'       => 'Ensembl and RefSeq transcripts'
        }]
      });
      
      $input_fieldset->add_field({
        'field_class'   => '_stt_rfq _stt_merged _stt_refseq',
        'type'    => 'checkbox',
        'name'    => "all_refseq",
        'label'   => 'Include additional EST and CCDS transcripts',
        'helptip' => 'The RefSeq transcript set also contains aligned EST and CCDS transcripts that are excluded by default',
        'value'   => 'yes',
        'checked' => 0
      });
    }

    ## Output options header
    $form->add_fieldset('Output options');

    ### Advanced config options
    my $sections = CONFIG_SECTIONS;
    foreach my $section (@$sections) {
      my $method      = '_build_'.$section->{'id'};
      my $config_div  = $form->append_child('div', {
        'class'       => 'extra_configs_wrapper vep-configs',
        'children'    => [{
          'node_name'   => 'div',
          'class'       => 'extra_configs_button',
          'children'    => [{
            'node_name'   => 'a',
            'rel'         => '_vep'.$section->{'id'},
            'class'       => [qw(toggle _slide_toggle set_cookie closed)],
            'href'        => '#vep'.$section->{'id'},
            'title'       => $section->{'caption'},
            'inner_HTML'  => $section->{'title'}
          }, {
            'node_name'   => 'span',
            'class'       => 'extra_configs_info',
            'inner_HTML'  => $section->{'caption'}
          }]
        }, {
          'node_name'   => 'div',
          'class'       => ['extra_configs', 'toggleable', 'hidden', '_vep'.$section->{'id'}],
        }]
      });

      $self->$method($form, $config_div->last_child); # add required fieldsets
    }

    # Placeholder for Run/Close buttons
    $form->append_child('text', 'BUTTONS_FIELDSET');

    $form = $form->render;

    # Save in cache to skip the form generation process next time
    $cache->set('VEPFORM', $form) if $cache;
  }

  # Add the non-cacheable fields to this dummy form and replace the placeholders from the actual form HTML
  my $fieldset2 = $self->new_form->add_fieldset;

  # Previous job params for JavaScript
  my $edit_job = ($hub->function || '') eq 'Edit' ? $self->object->get_edit_jobs_data : [];
     $edit_job = @$edit_job ? $fieldset2->add_hidden({ 'name'  => 'edit_jobs', 'value' => $self->jsonify($edit_job) }) : '';

  # Current species as hidden field
  my $species_input = $fieldset2->add_hidden({'name' => 'default_species', 'value' => $current_species});

  # Previously uploaded files
  my $file_dropdown   = '';
  my %allowed_formats = map { $_->{'value'} => $_->{'caption'} } @$input_formats;
  my @user_files      = sort { $b->{'timestamp'} <=> $a->{'timestamp'} } grep { $_->{'format'} && $allowed_formats{$_->{'format'}} } $hub->session->get_data('type' => 'upload'), $hub->user ? $hub->user->uploads : ();

  if (scalar @user_files) {
    my @to_form = { 'value' => '', 'caption' => '-- Select file --'};

    foreach my $record (@user_files) {

      my $file = EnsEMBL::Web::File::Tools->new('hub' => $hub, 'tool' => 'VEP', 'file' => $record->{'file'});
      my @file_data;
      try {
        @file_data    = @{$file->read_lines->{'content'}};
      } catch {};

      next unless @file_data;

      my $first_line  = first { $_ !~ /^\#/ } @file_data;
         $first_line  = substr($first_line, 0, 30).'&#8230;' if $first_line && length $first_line > 31;

      push @to_form, {
        'value'   => $record->{'code'},
        'caption' => sprintf('%s | %s | %s | %s',
          $file->read_name,
          $allowed_formats{$record->{'format'}},
          $sd->species_label($record->{'species'}, 1),
          $first_line || '-'
        )
      };
    }

    if (@to_form > 1) {
      $file_dropdown = $fieldset2->add_field({
        'type'    => 'dropdown',
        'name'    => 'userdata',
        'label'   => 'Or select previously uploaded file',
        'values'  => \@to_form,
      });
    }
  }

  # Buttons
  my $buttons_fieldset = $self->add_buttons_fieldset($fieldset2->form, {'reset' => 'Reset', 'cancel' => 'Close form'});

  # Add the render-time changes to the fields
  $fieldset2->prepare_to_render;

  # Regexp to replace all placeholders from cached form
  $form =~ s/SPECIES_INPUT/$species_input->render/e;
  $form =~ s/EDIT_JOB/$edit_job && $edit_job->render/e;
  $form =~ s/FILES_DROPDOWN/$file_dropdown && $file_dropdown->render/e;
  $form =~ s/BUTTONS_FIELDSET/$buttons_fieldset->render/e;

  # construct hash to pass to JS
  # containing information needed to render preview
  my %cons = map {$_->{SO_term} => {'description' => $_->{description}, 'rank' => $_->{rank}}} values %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;
  
  # add colours
  $cons{$_}->{colour} = $hub->colourmap->hex_by_name($sd->colour('variation')->{lc $_}->{'default'}) for keys %cons;
  
  # add example data
  my $ex_data;
  
  foreach my $sp(@$species) {
    foreach my $key(grep {/^VEP/} keys %{$sp->{sample}}) {
      my $value = $sp->{sample}->{$key};
      $key =~ s/^VEP\_//;
      $ex_data->{$sp->{value}}->{lc($key)} = $value;
    }
  }

  # create input with data
  my $panel_params = sprintf('<input class="js_param" type="hidden" name="preview_data" value="%s" /><input class="js_param" type="hidden" name="rest_server_url" value="%s"><input class="js_param" type="hidden" name="example_data" value="%s">',
    encode_entities($self->jsonify(\%cons)),
    encode_entities($sd->ENSEMBL_REST_URL),
    encode_entities($self->jsonify($ex_data))
  );

  return sprintf('
    %s<div class="hidden _tool_new">
      <p><a class="button _change_location" href="%s">New VEP job</a></p>
    </div>
    <div class="hidden _tool_form_div">
      <h2>New VEP job:</h2><input type="hidden" class="panel_type" value="VEPForm" />%s%s
    </div>',
    $panel_params,
    $hub->url({'function' => ''}),
    $self->species_specific_info($current_species, 'VEP', 'VEP'),
    $form
  );
}

sub _build_filters {
  my ($self, $form, $filter_div) = @_;
  my $fieldset  = $filter_div->append_child($form->add_fieldset('Filters'));

  if (first { $_->{'value'} eq 'Homo_sapiens' } @{$self->_species}) {

    $fieldset->add_field({
      'field_class'   => '_stt_Homo_sapiens',
      'label'         => 'By frequency',
      'helptip'       => 'Exclude common variants to remove input variants that overlap with known variants that have a minor allele frequency greater than 1% in the 1000 Genomes Phase 1 combined population. Use advanced filtering to change the population, frequency threshold and other parameters',
      'inline'        => 1,
      'elements'      => [{
        'type'          => 'radiolist',
        'name'          => 'frequency',
        'value'         => 'no',
        'class'         => '_stt',
        'values'        => [
          { 'value'       => 'no',        'caption' => 'No filtering'             },
          { 'value'       => 'common',    'caption' => 'Exclude common variants'  },
          { 'value'       => 'advanced',  'caption' => 'Advanced filtering'       }
        ]
      }, {
        'element_class' => '_stt_advanced',
        'type'          => 'dropdown',
        'name'          => 'freq_filter',
        'value'         => 'exclude',
        'values'        => [
          { 'value'       => 'exclude', 'caption' => 'Exclude'      },
          { 'value'       => 'include', 'caption' => 'Include only' }
        ]
      }, {
        'element_class' => '_stt_advanced',
        'type'          => 'dropdown',
        'name'          => 'freq_gt_lt',
        'value'         => 'gt',
        'values'        => [
          { 'value'       => 'gt', 'caption' => 'variants with MAF greater than' },
          { 'value'       => 'lt', 'caption' => 'variants with MAF less than'    },
        ]
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
        'values'        => [
          { 'value'       => '1kg_all', 'caption' => 'in 1000 genomes (1KG) combined population' },
          { 'value'       => '1kg_afr', 'caption' => 'in 1KG African combined population'        },
          { 'value'       => '1kg_amr', 'caption' => 'in 1KG American combined population'       },
          { 'value'       => '1kg_asn', 'caption' => 'in 1KG Asian combined population'          },
          { 'value'       => '1kg_eur', 'caption' => 'in 1KG European combined population'       },
          { 'value'       => 'esp_aa',  'caption' => 'in ESP African-American population'        },
          { 'value'       => 'esp_ea',  'caption' => 'in ESP European-American population'       },
        ],
      }]
    });
  }

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => "coding_only",
    'label'   => 'Return results for variants in coding regions only',
    'helptip' => 'Exclude results in intronic and intergenic regions',
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
}

sub _build_identifiers {
  my ($self, $form, $identifiers_div) = @_;
  my $hub       = $self->hub;
  my $species   = $self->_species;

  my $fieldset  = $identifiers_div->append_child($form->add_fieldset('Identifiers'));

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'symbol',
    'label'       => 'Gene symbol',
    'helptip'     => 'Report the gene symbol (e.g. HGNC)',
    'value'       => 'yes',
    'checked'     => 1
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_merged _stt_gencode_basic',
    'type'        => 'checkbox',
    'name'        => 'ccds',
    'label'       => 'CCDS',
    'helptip'     => 'Report the Consensus CDS identifier where applicable',
    'value'       => 'yes',
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'protein',
    'label'       => 'Protein',
    'helptip'     => 'Report the Ensembl protein identifier',
    'value'       => 'yes'
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'uniprot',
    'label'       => 'Uniprot',
    'helptip'     => 'Report identifiers from SWISSPROT, TrEMBL and UniParc',
    'value'       => 'yes'
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'hgvs',
    'label'       => 'HGVS',
    'helptip'     => 'Report HGVSc (coding sequence) and HGVSp (protein) notations for your variants',
    'value'       => 'yes'
  });

  # only for the species that have variants
  if (first { $_->{'variation'} } @$species) {

    $fieldset->add_field({
      'field_class' => '_stt_var',
      'label'       => 'Find co-located known variants',
      'helptip'     => "Report known variants from the Ensembl Variation database that are co-located with input. Use 'compare alleles' to only report co-located variants where none of the input variant's alleles are novel",
      'type'        => 'dropdown',
      'name'        => "check_existing",
      'value'       => 'yes',
      'class'       => '_stt',
      'values'      => [
        { 'value'     => 'no',      'caption' => 'No'                       },
        { 'value'     => 'yes',     'caption' => 'Yes'                      },
        { 'value'     => 'allele',  'caption' => 'Yes and compare alleles'  }
      ]
    });

    $fieldset->append_child('div', {
      'class'         => '_stt_Homo_sapiens',
      'children'      => [$fieldset->add_field({
        'type'          => 'checklist',
        'label'         => 'Frequency data for co-located variants',
        'field_class'   => [qw(_stt_yes _stt_allele)],
        'values'        => [{
          'name'          => "gmaf",
          'caption'       => '1000 Genomes global minor allele frequency',
          'helptip'       => 'Report the minor allele frequency for the combined 1000 Genomes Project phase 1 population',
          'value'         => 'yes',
          'checked'       => 1
        }, {
          'name'          => "maf_1kg",
          'caption'       => '1000 Genomes continental allele frequencies',
          'helptip'       => 'Report the allele frequencies for the combined 1000 Genomes Project phase 1 continental populations - AFR (African), AMR (American), ASN (Asian) and EUR (European)',
          'value'         => 'yes',
          'checked'       => 0
        }, {
          'name'          => "maf_esp",
          'caption'       => 'ESP allele frequencies',
          'helptip'       => 'Report the allele frequencies for the NHLBI Exome Sequencing Project populations - AA (African American) and EA (European American)',
          'value'         => 'yes',
          'checked'       => 0
        }]
      }), $fieldset->add_field({
        'type' => 'checkbox',
        'name' => 'pubmed',
        'label' => 'PubMed IDs for citations of co-located variants',
        'helptip' => 'Report the PubMed IDs of any publications that cite this variant',
        'value' => 'yes',
        'checked' => 1,
        'field_class'   => [qw(_stt_yes _stt_allele)],
      })]
    });
  }
}

sub _build_extra {
  my ($self, $form, $extra_div) = @_;
  my $hub       = $self->hub;
  my $sd        = $hub->species_defs;
  my $species   = $self->_species;
  my $fieldset  = $extra_div->append_child($form->add_fieldset);

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'biotype',
    'label'       => 'Transcript biotype',
    'helptip'     => 'Report the biotype of overlapped transcripts, e.g. protein_coding, miRNA, psuedogene',
    'value'       => 'yes',
    'checked'     => 1
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'domains',
    'label'       => 'Protein domains',
    'helptip'     => 'Report overlapping protein domains from Pfam, Prosite and InterPro',
    'value'       => 'yes',
    'checked'     => 0,
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'numbers',
    'label'       => 'Exon and intron numbers',
    'helptip'     => 'For variants that fall in the exon or intron, report the exon or intron number as NUMBER / TOTAL',
    'value'       => 'yes',
    'checked'     => 0
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'tsl',
    'label'       => 'Transcript support level',
    'helptip'     => 'Report the transcript support level',
    'value'       => 'yes',
    'checked'     => 1,
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'canonical',
    'label'       => 'Identify canonical transcripts',
    'helptip'     => 'Indicate if an affected transcript is the canonical transcript for the gene',
    'value'       => 'yes',
    'checked'     => 0,
  });

  # sift
  if (first { $_->{'variation'}{'SIFT'} } @$species) {

    $fieldset->add_field({
      'field_class' => '_stt_sift',
      'type'        => 'dropdown',
      'label'       => 'SIFT predictions',
      'helptip'     => 'Report SIFT scores and/or predictions for missense variants. SIFT is an algorithm to predict whether an amino acid substitution is likely to affect protein function',
      'name'        => 'sift',
      'value'       => 'both',
      'values'      => [
        { 'value'     => 'no',    'caption' => 'No'                   },
        { 'value'     => 'both',  'caption' => 'Prediction and score' },
        { 'value'     => 'pred',  'caption' => 'Prediction only'      },
        { 'value'     => 'score', 'caption' => 'Score only'           }
      ]
    });
  }

  # polyphen
  if (first { $_->{'variation'}{'POLYPHEN'} } @$species) {

    $fieldset->add_field({
      'field_class' => '_stt_pphn',
      'type'        => 'dropdown',
      'label'       => 'PolyPhen predictions',
      'helptip'     => 'Report PolyPhen scores and/or predictions for missense variants. PolyPhen is an algorithm to predict whether an amino acid substitution is likely to affect protein function',
      'name'        => 'polyphen',
      'value'       => 'both',
      'values'      => [
        { 'value'     => 'no',    'caption' => 'No'                   },
        { 'value'     => 'both',  'caption' => 'Prediction and score' },
        { 'value'     => 'pred',  'caption' => 'Prediction only'      },
        { 'value'     => 'score', 'caption' => 'Score only'           }
      ]
    });
  }

  # regulatory
  for (map { $_->{'regulatory'} ? $_->{'value'} : () } @$species) {

    $fieldset->add_field({
      'field_class'   => "_stt_$_",
      'label'         => 'Get regulatory region consequences',
      'helptip'       => 'Get consequences for variants that overlap regulatory features and transcription factor binding motifs',
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
        'caption'       => 'Select one or more cell types to limit regulatory feature results to. Hold Ctrl (Windows) or Cmd (Mac) to select multiple entries.',
        'no_input'      => 1,
        'element_class' => "_stt_cell_$_"
      }, {
        'element_class' => "_stt_cell_$_",
        'type'          => 'dropdown',
        'multiple'      => 1,
        'label'         => 'Limit to cell type(s)',
        'name'          => "cell_type_$_",
        'values'        => [ {'value' => '', 'caption' => 'None'}, map { 'value' => $_->name, 'caption' => $_->name }, @{$hub->get_adaptor('get_CellTypeAdaptor', 'funcgen', $_)->fetch_all} ]
      }]
    }) if $hub->get_adaptor('get_CellTypeAdaptor', 'funcgen', $_);
  }
}

sub _species {
  ## @private
  my $self = shift;

  if (!$self->{'_species'}) {
    my $hub     = $self->hub;
    my $sd      = $hub->species_defs;
    my %fav     = map { $_ => 1 } @{$hub->get_favourite_species};

    # at the moment only human, chicken and mouse have RefSeqs in their otherfeatures DB
    # there's no config for this currently so species are listed manually
    my %refseq  = map { $_ => 1 } qw(Danio_rerio Gallus_gallus Homo_sapiens Mus_musculus Rattus_norvegicus Sus_scrofa);
    my @species;

    for ($sd->tools_valid_species) {

      my $db_config = $sd->get_config($_, 'databases');

      push @species, {
        'value'       => $_,
        'caption'     => $sd->species_label($_, 1),
        'variation'   => $db_config->{'DATABASE_VARIATION'},
        'refseq'      => $refseq{$_} && $db_config->{'DATABASE_OTHERFEATURES'},
        'assembly'    => $sd->get_config($_, 'ASSEMBLY_NAME'),
        'regulatory'  => $sd->get_config($_, 'REGULATORY_BUILD'),
        'favourite'   => $fav{$_} || 0,
        'sample'      => $sd->get_config($_, 'SAMPLE_DATA'),
      };
    }

    @species = sort { ($a->{'favourite'} xor $b->{'favourite'}) ? $b->{'favourite'} || -1 : $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species'} = \@species;
  }

  return $self->{'_species'};
}

1;
