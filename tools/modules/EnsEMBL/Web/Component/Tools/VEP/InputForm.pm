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

package EnsEMBL::Web::Component::Tools::VEP::InputForm;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::TmpFile::Text;
use EnsEMBL::Web::Tools::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Exceptions;

use EnsEMBL::Web::VEPConstants qw(INPUT_FORMATS CONFIG_SECTIONS);

use base qw(EnsEMBL::Web::Component::Tools::VEP);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $sd        = $hub->species_defs;
  my $dom       = $self->dom;
  my $form      = $self->new_tool_form('VEP');
  my $edit_job  = $self->object->get_edit_jobs_data;

  ## Add the previous job params for JavaScript
  $form->add_hidden({ 'name'  => 'edit_jobs', 'value' => $self->jsonify($edit_job) }) if @$edit_job;

  my $input_fieldset  = $form->add_fieldset({'legend' => 'Input', 'class' => '_stt_input', 'no_required_notes' => 1});
  my %favourites      = map { $_ => 1 } @{$hub->get_favourite_species};
  my @species         = sort { ($a->{'fav'} xor $b->{'fav'}) ? $b->{'fav'} || -1 : $a->{'caption'} cmp $b->{'caption'} } map {'value' => $_, 'caption' => $sd->species_label($_, 1).': '.$sd->get_config($_, 'ASSEMBLY_NAME'), 'fav' => $favourites{$_} || 0}, $sd->valid_species;
  my $current_species = $hub->species;
  my $input_formats   = INPUT_FORMATS;

  $input_fieldset->add_field({
    'type'    => 'dropdown',
    'name'    => 'species',
    'label'   => 'Species',
    'values'  => \@species,
    'value'   => $current_species,
    'class'   => '_stt'
  });

  $input_fieldset->add_field({
    'type'    => 'string',
    'name'    => 'name',
    'label'   => 'Name for this data (optional)'
  });

  $input_fieldset->add_field({
    'type'    => 'dropdown',
    'name'    => 'format',
    'label'   => 'Input file format (<a href="/info/docs/tools/vep/vep_formats.html#input" class="popup">details</a>)',
    'values'  => $input_formats,
    'value'   => 'ensembl',
    'class'   => '_stt format'
  });

  for (@$input_formats) {
    $input_fieldset->add_field({
      'field_class' => '_stt_'.$_->{'value'},
      'type'        => 'Text',
      'name'        => 'text_'.$_->{'value'},
      'value'       => $_->{'example'},
      'label'       => 'Either paste data'
    });
  }

  $input_fieldset->add_field({
    'type'    => 'file',
    'name'    => 'file',
    'label'   => 'Or upload file',
    'helptip' => 'File uploads are limited to 5MB in size. Files may be compressed using gzip or zip'
  });

  $input_fieldset->add_field({
    'type'    => 'url',
    'name'    => 'url',
    'label'   => 'Or provide file URL',
    'size'    => 30,
    'class'   => 'url'
  });

  my %allowed_formats = map { $_->{'value'} => $_->{'caption'} } @$input_formats;
  my @user_files      = sort { $b->{'timestamp'} <=> $a->{'timestamp'} } grep { $allowed_formats{$_->{'format'}} } $hub->session->get_data('type' => 'upload'), $hub->user ? $hub->user->uploads : ();

  if (scalar @user_files) {
    my @to_form = { 'value' => '', 'caption' => '-- Select file --'};

    foreach my $file (@user_files) {

      my $file_obj    = EnsEMBL::Web::TmpFile::Text->new('filename' => $file->{'filename'});
      my $file_data   = '';
      try {
        $file_data    = file_get_contents($file_obj->full_path);
      } catch {};

      next unless $file_data;

      my $first_line  = first { $_ !~ /^\#/ } $file_data;
         $first_line  = substr($first_line, 0, 30).'&#8230;' if $first_line && length $first_line > 31;

      push @to_form, {
        'value'   => $file->{'filename'},
        'caption' => sprintf('%s | %s | %s | %s',
          $file->{'name'},
          $allowed_formats{$file->{'format'}},
          $sd->species_label($file->{'species'}, 1),
          $first_line || '-'
        )
      };
    }

    if (@to_form > 1) {
      $input_fieldset->add_field({
        'type'    => 'dropdown',
        'name'    => 'userdata',
        'label'   => 'Or select previously uploaded file',
        'values'  => \@to_form,
      });
    }
  }

  # have otherfeatures?
  #foreach my $sp ($sd->valid_species) {
  #  if ($sd->get_config($sp, 'databases')->{'DATABASE_OTHERFEATURES'}) {
  #    my $div = $self->dom->create_element('div', {class => '_stt_'.$sp});
  #
  #    $div->append_child($input_fieldset->add_field({
  #        'type'    => 'radiolist',
  #        'name'    => 'core_type_'.$sp,
  #        'label'   => 'Transcript database to use',
  #        'helptip' => 'Select RefSeq to use the otherfeatures transcript database, which contains basic aligned RefSeq transcript sequences in place of complete Ensembl transcript models'
  #        'values'  => [
  #          { value => 'core',   caption => 'Ensembl transcripts'          },
  #          { value => 'refseq', caption => 'RefSeq and other transcripts' },
  #        ],
  #        'value'   => 'core',
  #    }));
  #
  #    $input_fieldset->append_child($div);
  #  }
  #}


  ## Output options header
  $form->add_fieldset('Output options');

  ### Advanced config options
  my @sections = ({
    'id'        => 'identifiers',
    'title'     => 'Identifiers and frequency data',
    'caption'   => 'Additional identifiers for genes, transcripts and variants; frequency data'
  }, {
    'id'        => 'filters',
    'title'     => 'Filtering options',
    'caption'   => 'Pre-filter results by frequency or consequence type'
  }, {
    'id'        => 'extra',
    'title'     => 'Extra options',
    'caption'   => 'e.g. SIFT, PolyPhen and regulatory data'
  });

  foreach my $section (@sections) {
    my $show        = $hub->get_cookie_value('toggle_vep'.$section->{'id'}) eq 'open' || 0;
    my $method      = '_build_'.$section->{'id'};
    my $config_div  = $form->append_child('div', {
      'class'       => 'extra_configs_wrapper vep-configs',
      'children'    => [{
        'node_name'   => 'div',
        'class'       => 'extra_configs_button',
        'children'    => [{
          'node_name'   => 'a',
          'rel'         => '_vep'.$section->{'id'},
          'class'       => ['toggle', 'set_cookie', $show ? 'open' : 'closed'],
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
        'class'       => ['extra_configs', 'toggleable', $show ? () : 'hidden', '_vep'.$section->{'id'}],
      }]
    });

    $self->$method($form, $config_div->last_child); # add required fieldsets
  }

  $self->add_buttons_fieldset($form, {'reset' => 'Reset', 'cancel' => 'Cancel'});

  return sprintf('
    <div class="hidden _tool_new">
      <p><a class="button _change_location" href="%s">New VEP job</a></p>
    </div>
    <div class="hidden _tool_form_div">
      <h2>New VEP job:</h2><input type="hidden" class="panel_type" value="VEPForm" />%s
    </div>',
    $hub->url({'function' => ''}),
    $form->render
  );
}

sub _build_filters {
  my ($self, $form, $filter_div) = @_;
  my $dom       = $self->dom;
  my $fieldset  = $filter_div->append_child($form->add_fieldset('Filters'));

  $fieldset->append_child($dom->create_element('div', {'class' => '_stt_Homo_sapiens'}))->append_children(
    $fieldset->add_field({
      'type'    => 'radiolist',
      'name'    => 'frequency',
      'label'   => 'By frequency',
      'helptip' => 'Exclude common variants to remove input variants that overlap with known variants that have a minor allele frequency greater than 1% in the 1000 Genomes Phase 1 combined population. Use advanced filtering to change the population, frequency threshold and other parameters',
      'value'   => 'no',
      'class'   => '_stt',
      'values'  => [
        { 'value' => 'no',        'caption' => 'No filtering' },
        { 'value' => 'common',    'caption' => 'Exclude common variants' },
        { 'value' => 'advanced',  'caption' => 'Advanced filtering' },
      ]
    }), {
      'node_name' => 'div',
      'class'     => '_stt_advanced',
      'children'  => [
        $fieldset->add_field({
          'type'    => 'dropdown',
          'label'   => 'Filter',
          'name'    => 'freq_filter',
          'value'   => 'exclude',
          'values'  => [
            { 'value' => 'exclude', 'caption' => 'Exclude' },
            { 'value' => 'include', 'caption' => 'Include only' },
          ]
        }),
        $fieldset->add_field({
          'type'    => 'dropdown',
          'name'    => 'freq_gt_lt',
          'value'   => 'gt',
          'values'  => [
            { 'value' => 'gt', 'caption' => 'variants with MAF greater than' },
            { 'value' => 'lt', 'caption' => 'variants with MAF less than'    },
          ]
        }),
        $fieldset->add_field({
          'type'    => 'string',
          'name'    => 'freq_freq',
          'value'   => '0.01',
          'max'     => 1,
        }),
        $fieldset->add_field({
          'type'    => 'dropdown',
          'name'    => 'freq_pop',
          'value'   => '1kg_all',
          'values'  => [
            { 'value' => '1kg_all', 'caption' => 'in 1000 genomes (1KG) combined population' },
            { 'value' => '1kg_afr', 'caption' => 'in 1KG African combined population'        },
            { 'value' => '1kg_amr', 'caption' => 'in 1KG American combined population'       },
            { 'value' => '1kg_asn', 'caption' => 'in 1KG Asian combined population'          },
            { 'value' => '1kg_eur', 'caption' => 'in 1KG European combined population'       },
            { 'value' => 'esp_aa',  'caption' => 'in ESP African-American population'        },
            { 'value' => 'esp_ea',  'caption' => 'in ESP European-American population'       },
#             { 'value' => '-',       'caption' => '-----'                                     },
#             { 'value' => '1kg_asw', 'caption' => 'in 1KG ASW population'                     },
#             { 'value' => '1kg_ceu', 'caption' => 'in 1KG CEU population'                     },
#             { 'value' => '1kg_chb', 'caption' => 'in 1KG CHB population'                     },
#             { 'value' => '1kg_chs', 'caption' => 'in 1KG CHS population'                     },
#             { 'value' => '1kg_clm', 'caption' => 'in 1KG CLM population'                     },
#             { 'value' => '1kg_fin', 'caption' => 'in 1KG FIN population'                     },
#             { 'value' => '1kg_gbr', 'caption' => 'in 1KG GBR population'                     },
#             { 'value' => '1kg_ibs', 'caption' => 'in 1KG IBS population'                     },
#             { 'value' => '1kg_jpt', 'caption' => 'in 1KG JPT population'                     },
#             { 'value' => '1kg_lwk', 'caption' => 'in 1KG LWK population'                     },
#             { 'value' => '1kg_mxl', 'caption' => 'in 1KG MXL population'                     },
#             { 'value' => '1kg_pur', 'caption' => 'in 1KG PUR population'                     },
#             { 'value' => '1kg_tsi', 'caption' => 'in 1KG TSI population'                     },
#             { 'value' => '1kg_yri', 'caption' => 'in 1KG YRI population'                     },
#             { 'value' => '-',       'caption' => '-----'                                     },
#             { 'value' => 'hap_asw', 'caption' => 'in HapMap ASW'                             },
#             { 'value' => 'hap_ceu', 'caption' => 'in HapMap CEU'                             },
#             { 'value' => 'hap_chb', 'caption' => 'in HapMap CHB'                             },
#             { 'value' => 'hap_chd', 'caption' => 'in HapMap CHD'                             },
#             { 'value' => 'hap_gih', 'caption' => 'in HapMap GIH'                             },
#             { 'value' => 'hap_jpt', 'caption' => 'in HapMap JPT'                             },
#             { 'value' => 'hap_lwk', 'caption' => 'in HapMap LWK'                             },
#             { 'value' => 'hap_mex', 'caption' => 'in HapMap MEX'                             },
#             { 'value' => 'hap_mkk', 'caption' => 'in HapMap MKK'                             },
#             { 'value' => 'hap_tsi', 'caption' => 'in HapMap TSI'                             },
#             { 'value' => 'hap_yri', 'caption' => 'in HapMap YRI'                             },
#             { 'value' => 'hap',     'caption' => 'in any HapMap population'                  },
#             { 'value' => '-',       'caption' => '-----'                                     },
#             { 'value' => 'any',     'caption' => 'any 1KG phase 1 or HapMap population'      },
          ],
#           ''notes   => '<strong>NB:</strong> Enabling advanced frequency filtering may be slow for large datasets',
        })
      ]
    }
  );

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
    'notes'   => '<strong>NB:</strong> Restricting results may exclude biologically important data!',
    'values'  => [
      { 'value' => 'no',          'caption' => 'Show all results' },
      { 'value' => 'per_gene',    'caption' => 'Show most severe per gene' },
      { 'value' => 'summary',     'caption' => 'Show only list of consequences per variant' },
      { 'value' => 'most_severe', 'caption' => 'Show most severe per variant' },
    ]
  });
}

sub _build_identifiers {
  my ($self, $form, $identifiers_div) = @_;
  my $dom       = $self->dom;
  my $hub       = $self->hub;
  my $sd        = $hub->species_defs;

  my $fieldset  = $identifiers_div->append_child($form->add_fieldset('Identifiers'));

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => 'symbol',
    'label'   => 'Gene symbol',
    'helptip' => 'Report the gene symbol (e.g. HGNC)',
    'value'   => 'yes',
    'checked' => 1
  });

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => 'ccds',
    'label'   => 'CCDS',
    'helptip' => 'Report the Consensus CDS identifier where applicable',
    'value'   => 'yes'
  });

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => 'protein',
    'label'   => 'Protein',
    'helptip' => 'Report the Ensembl protein identifier',
    'value'   => 'yes'
  });

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => 'hgvs',
    'label'   => 'HGVS',
    'helptip' => 'Report HGVSc (coding sequence) and HGVSp (protein) notations for your variants',
    'value'   => 'yes'
  });

  # have variants?
  foreach my $sp ($sd->valid_species) {
    if ($sd->get_config($sp, 'databases')->{'DATABASE_VARIATION'}) {
      my $species_div = $fieldset->append_child('div', {
        'class'     => "_stt_$sp",
        'children'  => [
          $fieldset->add_field({
            'type'    => 'dropdown',
            'label'   => 'Find co-located known variants',
            'helptip' => "Report known variants from the Ensembl Variation database that are co-located with input. Use  'compare alleles' to only report co-located variants where none of the input variant's alleles are novel",
            'name'    => "check_existing_$sp",
            'value'   => 'yes',
            'class'   => '_stt',
            'values'  => [
              { 'value' => 'no',      'caption' => 'No'                       },
              { 'value' => 'yes',     'caption' => 'Yes'                      },
              { 'value' => 'allele',  'caption' => 'Yes and compare alleles'  },
            ]
          })
        ]
      });

      # add frequency fields
      if ($sp eq 'Homo_sapiens') {

        my $freq_fieldset = $identifiers_div->append_child($form->add_fieldset({ 'legend' => 'Frequency data for co-located variants', 'class' => "_stt_$sp" }));

        for (qw(yes allele)) {

          $freq_fieldset->add_field({
            'field_class' => "_stt_$_",
            'type'        => 'checkbox',
            'name'        => "gmaf_$_",
            'label'       => '1000 Genomes global minor allele frequency',
            'helptip'     => 'Report the minor allele frequency for the combined 1000 Genomes Project phase 1 population',
            'value'       => 'yes',
            'checked'     => 1
          });
          $freq_fieldset->add_field({
            'field_class' => "_stt_$_",
            'type'        => 'checkbox',
            'name'        => "maf_1kg_$_",
            'label'       => '1000 Genomes continental minor allele frequencies',
            'helptip'     => 'Report the minor allele frequencies for the combined 1000 Genomes Project phase 1 continental populations - AFR (African), AMR (American), ASN (Asian) and EUR (European)',
            'value'       => 'yes',
            'checked'     => 0
          });
          $freq_fieldset->add_field({
            'field_class' => "_stt_$_",
            'type'        => 'checkbox',
            'name'        => "maf_esp_$_",
            'label'       => 'ESP minor allele frequencies',
            'helptip'     => 'Report the minor allele frequencies for the NHLBI Exome Sequencing Project populations - AA (African American) and EA (European American)',
            'value'       => 'yes',
            'checked'     => 0
          });
        }
      }
    }
  }
}

sub _build_extra {
  my ($self, $form, $extra_div) = @_;
  my $hub       = $self->hub;
  my $sd        = $hub->species_defs;
  my $fieldset  = $extra_div->append_child($form->add_fieldset);

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => 'biotype',
    'label'   => 'Transcript biotype',
    'helptip' => 'Report the biotype of overlapped transcripts, e.g. protein_coding, miRNA, psuedogene',
    'value'   => 'yes',
    'checked' => 1
  });

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => 'domains',
    'label'   => 'Protein domains',
    'helptip' => 'Report overlapping protein domains from Pfam, Prosite and InterPro',
    'value'   => 'yes',
    'checked' => 0
  });

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => 'numbers',
    'label'   => 'Exon and intron numbers',
    'helptip' => 'For variants that fall in the exon or intron, report the exon or intron number as NUMBER / TOTAL',
    'value'   => 'yes',
    'checked' => 0
  });

  $fieldset->add_field({
    'type'    => 'checkbox',
    'name'    => 'canonical',
    'label'   => 'Identify canonical transcripts',
    'helptip' => 'Indicate if an affected transcript is the canonical transcript for the gene',
    'value'   => 'yes',
    'checked' => 0
  });

  # species-specific stuff
  foreach my $sp ($sd->valid_species) {

    # sift?
    if ($sd->get_config($sp, 'databases')->{'DATABASE_VARIATION'}->{'SIFT'}) {

      $fieldset->add_field({
        'field_class' => "_stt_$sp",
        'type'        => 'dropdown',
        'label'       => 'SIFT predictions',
        'helptip'     => 'Report SIFT scores and/or predictions for missense variants. SIFT is an algorithm to predict whether an amino acid substitution is likely to affect protein function',
        'name'        => "sift_$sp",
        'value'       => 'both',
        'values'      => [
          { 'value' => 'no',    'caption' => 'No'                   },
          { 'value' => 'both',  'caption' => 'Prediction and score' },
          { 'value' => 'pred',  'caption' => 'Prediction only'      },
          { 'value' => 'score', 'caption' => 'Score only'           }
        ]
      });
    }

    # polyphen?
    if ($sd->get_config($sp, 'databases')->{'DATABASE_VARIATION'}->{'POLYPHEN'}) {

      $fieldset->add_field({
        'field_class' => "_stt_$sp",
        'type'        => 'dropdown',
        'label'       => 'PolyPhen predictions',
        'helptip'     => 'Report PolyPhen scores and/or predictions for missense variants. PolyPhen is an algorithm to predict whether an amino acid substitution is likely to affect protein function',
        'name'        => "polyphen_$sp",
        'value'       => 'both',
        'values'      => [
          { 'value' => 'no',    'caption' => 'No'                   },
          { 'value' => 'both',  'caption' => 'Prediction and score' },
          { 'value' => 'pred',  'caption' => 'Prediction only'      },
          { 'value' => 'score', 'caption' => 'Score only'           }
        ]
      });
    }

    # regulatory
    if($sd->get_config($sp, 'REGULATORY_BUILD')) {

      $fieldset->add_field({
        'field_class' => "_stt_$sp",
        'type'        => 'dropdown',
        'name'        => "regulatory_$sp",
        'class'       => '_stt',
        'label'       => 'Get regulatory region consequences',
        'helptip'     => 'Get consequences for variants that overlap regulatory features and transcription factor binding motifs',
        'value'       => 'reg',
        'values'      => [
          { 'value' => 'no',   'caption' => 'No'                          },
          { 'value' => 'reg',  'caption' => 'Yes'                         },
          { 'value' => 'cell', 'caption' => 'Yes and limit by cell type'  },
        ],
      });

      my $cell_type_adaptor = $hub->get_adaptor('get_CellTypeAdaptor', 'funcgen', $sp);

      $fieldset->add_field({
        'field_class' => "_stt_cell _stt_$sp",
        'type'        => 'dropdown',
        'multiple'    => 1,
        'label'       => 'Limit to cell type(s)',
        'helptip'     => 'Select one or more cell types to limit regulatory feature results to. Hold Ctrl (Windows) or Cmd (Mac) to select multiple entries',
        'name'        => 'cell_type',
        'values'      => [ {'value' => '', 'caption' => 'None'}, map { 'value' => $_->name, 'caption' => $_->name }, @{$cell_type_adaptor->fetch_all} ]
      });
    }
  }
}

1;
