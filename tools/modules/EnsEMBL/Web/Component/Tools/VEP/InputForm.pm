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

use parent qw(EnsEMBL::Web::Component::Tools::VEP);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $sd              = $hub->species_defs;
  my $species         = $self->_species;
  my $cache           = $hub->cache;
  my $form            = $cache ? $cache->get('VEPFORM') : undef;
  my $current_species = $hub->species;
  my $input_formats   = INPUT_FORMATS;

  if (!$form) {
    $form = $self->new_tool_form('VEP');

    # Placeholder for previous job json hidden input
    $form->append_child('text', 'EDIT_JOB');

    my $input_fieldset = $form->add_fieldset({'legend' => 'Input', 'class' => '_stt_input', 'no_required_notes' => 1});

    # Placeholder for species dropdown
    $input_fieldset->append_child('text', 'SPECIES_DROPDOWN');

    $input_fieldset->add_field({
      'type'          => 'string',
      'name'          => 'name',
      'label'         => 'Name for this data (optional)'
    });

    $input_fieldset->add_field({
      'type'          => 'dropdown',
      'name'          => 'format',
      'label'         => sprintf('Input file format (<a href="%s#input" class="popup">details</a>)', $hub->url({
        'type'          => 'Help',
        'action'        => 'View',
        'id'            => { $sd->multiX('ENSEMBL_HELP') }->{'Tools/VEP/VEP_formats'},
        '__clear'       => 1
      })),
      'values'        => [ map { { %$_, 'class' => ['_stt_var', $_->{'value'} =~ /id|hgvs/ ? () : '_stt_novar'] } } @$input_formats ],  # species without variation DBs can't use ID or HGVS (currently)
      'value'         => 'ensembl',
      'class'         => '_stt format'
    });

    $input_fieldset->add_field({
      'label'         => 'Either paste data',
      'elements'      => [ map {
        'type'          => 'text',
        'name'          => 'text_'.$_->{'value'},
        'element_class' => '_stt_'.$_->{'value'},
        'value'         => $_->{'example'},
      }, @$input_formats ]
    });

    $input_fieldset->add_field({
      'type'          => 'file',
      'name'          => 'file',
      'label'         => 'Or upload file',
      'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $sd->ENSEMBL_VEP_CGI_POST_MAX / 1048576)
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
        'helptip'       => 'Select RefSeq to use the otherfeatures transcript database, which contains basic aligned RefSeq transcript sequences in place of complete Ensembl transcript models',
        'value'         => 'core',
        'class'         => '_stt',
        'values'        => [{
          'value'         => 'core',
          'caption'       => 'Ensembl transcripts'
        }, {
          'value'         => 'refseq',
          'caption'       => 'RefSeq and other transcripts'
        }]
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

    $self->add_buttons_fieldset($form, {'reset' => 'Reset', 'cancel' => 'Cancel'});

    $form = $form->render;

    # Save in cache to skip the form generation process next time
    $cache->set('VEPFORM', $form) if $cache;
  }

  # Add the non-cacheable fields to this dummy form and replace the placeholders from the actual form HTML
  my $form2 = $self->new_form;

  # Previous job params for JavaScript
  my $edit_job = ($hub->function || '') eq 'Edit' ? $self->object->get_edit_jobs_data : [];
     $edit_job = @$edit_job ? $form2->add_hidden({ 'name'  => 'edit_jobs', 'value' => $self->jsonify($edit_job) })->render : '';

  # Species dropdown list with stt classes to dynamically toggle other fields
  my $species_dropdown = $form2->add_field({
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
      'value'         => 'Assembly: '. join('', map { sprintf '<span class="_stt_%s">%s</span>', $_->{'value'}, $_->{'assembly'} } @$species),
      'no_input'      => 1,
      'is_html'       => 1
    }]
  })->render;

  # Previously uploaded files
  my $file_dropdown   = '';
  my %allowed_formats = map { $_->{'value'} => $_->{'caption'} } @$input_formats;
  my @user_files      = sort { $b->{'timestamp'} <=> $a->{'timestamp'} } grep { $_->{'format'} && $allowed_formats{$_->{'format'}} } $hub->session->get_data('type' => 'upload'), $hub->user ? $hub->user->uploads : ();

  if (scalar @user_files) {
    my @to_form = { 'value' => '', 'caption' => '-- Select file --'};

    foreach my $file (@user_files) {

      my $file_obj    = EnsEMBL::Web::TmpFile::Text->new('filename' => $file->{'filename'});
      my @file_data;
      try {
        @file_data    = file_get_contents($file_obj->full_path);
      } catch {};

      next unless @file_data;

      my $first_line  = first { $_ !~ /^\#/ } @file_data;
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
      $file_dropdown = $form2->add_field({
        'type'    => 'dropdown',
        'name'    => 'userdata',
        'label'   => 'Or select previously uploaded file',
        'values'  => \@to_form,
      })->render;
    }
  }

  # Regexp to replace all placeholders from cached form
  $form =~ s/EDIT_JOB/$edit_job/;
  $form =~ s/SPECIES_DROPDOWN/$species_dropdown/;
  $form =~ s/FILES_DROPDOWN/$file_dropdown/;

  return sprintf('
    <div class="hidden _tool_new">
      <p><a class="button _change_location" href="%s">New VEP job</a></p>
    </div>
    <div class="hidden _tool_form_div">
      <h2>New VEP job:</h2><input type="hidden" class="panel_type" value="VEPForm" />%s
    </div>',
    $hub->url({'function' => ''}),
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
    'field_class' => '_stt_core',
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
          'caption'       => '1000 Genomes continental minor allele frequencies',
          'helptip'       => 'Report the minor allele frequencies for the combined 1000 Genomes Project phase 1 continental populations - AFR (African), AMR (American), ASN (Asian) and EUR (European)',
          'value'         => 'yes',
          'checked'       => 0
        }, {
          'name'          => "maf_esp",
          'caption'       => 'ESP minor allele frequencies',
          'helptip'       => 'Report the minor allele frequencies for the NHLBI Exome Sequencing Project populations - AA (African American) and EA (European American)',
          'value'         => 'yes',
          'checked'       => 0
        }]
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
    'field_class' => '_stt_core',
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
    'field_class' => '_stt_core',
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
    });
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
    my %refseq  = map { $_ => 1 } qw(Gallus_gallus Homo_sapiens Mus_musculus);
    my @species;

    for ($sd->valid_species) {

      my $db_config = $sd->get_config($_, 'databases');

      push @species, {
        'value'       => $_,
        'caption'     => $sd->species_label($_, 1),
        'variation'   => $db_config->{'DATABASE_VARIATION'},
        'refseq'      => $refseq{$_} && $db_config->{'DATABASE_OTHERFEATURES'},
        'assembly'    => $sd->get_config($_, 'ASSEMBLY_NAME'),
        'regulatory'  => $sd->get_config($_, 'REGULATORY_BUILD'),
        'favourite'   => $fav{$_} || 0
      };
    }

    @species = sort { ($a->{'favourite'} xor $b->{'favourite'}) ? $b->{'favourite'} || -1 : $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species'} = \@species;
  }

  return $self->{'_species'};
}

1;