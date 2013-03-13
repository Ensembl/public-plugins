package EnsEMBL::Web::Component::Tools::VEPInputForm;

use strict;
use warnings;
no warnings 'uninitialized';


use base qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  my $html = '<div style="width:932px">';
  $html .= '<input type="hidden" class="panel_type" value="VepForm" />';
  $html .= '<br />';

  my $form = EnsEMBL::Web::Form->new({
    id     => 'vep_input',
    action => '/Tools/Submit',
    method =>  'post',
    class  => 'vep',
    validate => 0
  });

   ## Species now set automatically for the page you are on
  my @species;

  my $current_species = $hub->species;
  foreach my $sp ($hub->species_defs->valid_species) {
    push @species, {'value' => $sp, 'name' => $hub->species_defs->species_label($sp, 1).': '.$hub->species_defs->get_config($sp, 'ASSEMBLY_NAME')};
  }
  @species = sort {$a->{'name'} cmp $b->{'name'}} @species;

  $form->add_element(
      'type'    => 'DropDown',
      'name'    => 'species',
      'label'   => "Species",
      'values'  => \@species,
      'value'   => $current_species,
      'select'  => 'select',
      'width'   => '300px',
  );

  $form->add_element(
      'type'    => 'DropDown',
      'name'    => 'format',
      'label'   => "Input file format",
      'values'  => [
        { value => 'snp',     name => 'Ensembl default'     },
        { value => 'vep_vcf', name => 'VCF'                 },
        { value => 'pileup',  name => 'Pileup'              },
        { value => 'id',      name => 'Variant identifiers' },
        { value => 'id',      name => 'HGVS notations'      },
      ],
      'value'   => 'snp',
      'select'  => 'select',
  );

  my $example = qq(1  881907  881906  -/C  +
5  140532  140532  T/C  +);

  $form->add_element( type => 'String', name => 'name', label => 'Name for this data (optional)' );
  $form->add_element( type => 'Text', name => 'text', label => 'Paste data', value => $example );
  $form->add_element( type => 'File', name => 'file', label => 'Upload file' );
  $form->add_element( type => 'URL',  name => 'url',  label => 'Provide file URL', size => 30 );

  my $userdata = [];
  $form->add_element(
      'type'    => 'DropDown',
      'name'    => 'userdata',
      'label'   => "or previously select uploaded file",
      'values'  => $userdata,
      'select'  => 'select',
  );

  $form->add_element(
      'type'    => 'RadioGroup',
      'name'    => 'core_type',
      'label'   => "Transcript database to use",
      'values'  => [
        { value => 'core',          name => 'Ensembl transcripts'          },
        { value => 'otherfeatures', name => 'RefSeq and other transcripts' },
      ],
      'value'   => 'core',
      'select'  => 'select',
  );

  $form->add_element(
    type    => 'Submit',
    name    => 'submit_vep',
    value   => 'Run >',
    class   => 'submit_vep',
  );

### Advanced config options ###

  my $show    = $hub->get_cookie_value('toggle_vep') eq 'open' || 1;
  my $style   = $show ? '' : 'display:none';

  my $configuration = sprintf('<a rel="vep" class="toggle set_cookie %s" style="border-bottom-width:%s" href="#" title="Click to see configuration options">Configuration Options</a>',
                     $show ? 'open' : 'closed',
                     $show ? '0px' : '2px'
                    );

  $form->add_notes($configuration)->set_attribute('class', 'config');

  ## Filters
  my $filter_fieldset = $form->add_fieldset({'class' => '_stt_filters', 'no_required_notes' => 1});
  $filter_fieldset->legend('Filters');

  $filter_fieldset->add_field({
    type  => 'CheckBox',
    name  => "coding_only",
    label => "Return results for variants in coding regions only",
    value => 'yes',
    selected => 0
  });

  $filter_fieldset->add_field({
      'type'    => 'Radiolist',
      'name'    => 'frequency',
      'label'   => "By frequency",
      'values'  => [
        { value => 'common',    caption => 'Exclude common variants' },
        { value => 'advanced',  caption => 'Advanced filtering' },
      ],
      'value'   => 'common',
      'select'  => 'select',
      'notes'   => '<strong>NB:</strong> Enabling frequency filtering may be slow for large datasets. The default options will filter out common variants found by the 1000 Genomes project.',
  });

  $filter_fieldset->add_field({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'Filter',
    name   => 'freq_filter',
    values => [
      { value => 'exclude', caption => 'Exclude' },
      { value => 'include', caption => 'Include only' },
    ],
    value  => 'exclude',
    select => 'select',
  });

  $filter_fieldset->add_field({
    type   => 'DropDown',
    select =>, 'select',
    #label  => '',
    name   => 'freq_gt_lt',
    values => [
      { value => 'gt', caption => 'variants with MAF greater than' },
      { value => 'lt', caption => 'variants with MAF less than'    },
    ],
    value  => 'gt',
    select => 'select',
  });

  $filter_fieldset->add_field({
    type  => 'String',
    name  => 'freq_freq',
    value => '0.01',
    max   => 1,
  });

  $form->add_element(
    type   => 'DropDown',
    select =>, 'select',
    #label  => '',
    name   => 'freq_pop',
    values => [
      { value => '1kg_all', caption => 'in 1000 genomes (1KG) combined population' },
      { value => '1kg_afr', caption => 'in 1KG African combined population'        },
      { value => '1kg_amr', caption => 'in 1KG American combined population'       },
      { value => '1kg_asn', caption => 'in 1KG Asian combined population'          },
      { value => '1kg_eur', caption => 'in 1KG European combined population'       },
      { value => '-',       caption => '-----'                                     },
      { value => '1kg_asw', caption => 'in 1KG ASW population'                     },
      { value => '1kg_ceu', caption => 'in 1KG CEU population'                     },
      { value => '1kg_chb', caption => 'in 1KG CHB population'                     },
      { value => '1kg_chs', caption => 'in 1KG CHS population'                     },
      { value => '1kg_clm', caption => 'in 1KG CLM population'                     },
      { value => '1kg_fin', caption => 'in 1KG FIN population'                     },
      { value => '1kg_gbr', caption => 'in 1KG GBR population'                     },
      { value => '1kg_ibs', caption => 'in 1KG IBS population'                     },
      { value => '1kg_jpt', caption => 'in 1KG JPT population'                     },
      { value => '1kg_lwk', caption => 'in 1KG LWK population'                     },
      { value => '1kg_mxl', caption => 'in 1KG MXL population'                     },
      { value => '1kg_pur', caption => 'in 1KG PUR population'                     },
      { value => '1kg_tsi', caption => 'in 1KG TSI population'                     },
      { value => '1kg_yri', caption => 'in 1KG YRI population'                     },
      { value => '-',       caption => '-----'                                     },
      { value => 'hap_asw', caption => 'in HapMap ASW'                             },
      { value => 'hap_ceu', caption => 'in HapMap CEU'                             },
      { value => 'hap_chb', caption => 'in HapMap CHB'                             },
      { value => 'hap_chd', caption => 'in HapMap CHD'                             },
      { value => 'hap_gih', caption => 'in HapMap GIH'                             },
      { value => 'hap_jpt', caption => 'in HapMap JPT'                             },
      { value => 'hap_lwk', caption => 'in HapMap LWK'                             },
      { value => 'hap_mex', caption => 'in HapMap MEX'                             },
      { value => 'hap_mkk', caption => 'in HapMap MKK'                             },
      { value => 'hap_tsi', caption => 'in HapMap TSI'                             },
      { value => 'hap_yri', caption => 'in HapMap YRI'                             },
      { value => 'hap',     caption => 'in any HapMap population'                  },
      { value => '-',       caption => '-----'                                     },
      { value => 'any',     caption => 'any 1KG phase 1 or HapMap population'      },
    ],
    value  => '1kg_all',
    select => 'select',
  );

  ## Identifiers
  my $ident_fieldset = $form->add_fieldset({
      'class'             => '_stt_ident', 
      'no_required_notes' => 1,
      'legend'            => 'Identifiers',
      'head_notes'        => 'Show the following identifiers where available',
  });

  $ident_fieldset->add_field({
    type  => 'CheckBox',
    name  => "hgnc",
    label => "HGNC",
    value => 'yes',
    selected => 0
  });

  $ident_fieldset->add_field({
    type  => 'CheckBox',
    name  => "protein",
    label => "Proteins",
    value => 'yes',
    selected => 0
  });

  $ident_fieldset->add_field({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'HGVS',
    name   => 'hgvs',
    values => [
      { value => 'no',             caption => 'No'                           },
      { value => 'coding',         caption => 'Coding sequence only'         },
      { value => 'protein',        caption => 'Protein sequence only'        },
      { value => 'coding_protein', caption => 'Coding and protein sequence'  },
    ],
    value  => 'no',
    select => 'select',
  });

  $ident_fieldset->add_field({
    type   => 'DropDown',
    label  => 'Co-located variants',
    name   => 'check_existing',
    values => [
      { value => 'no',     caption => 'No'                      },
      { value => 'yes',    caption => 'Yes'                     },
      { value => 'allele', caption => 'Yes and compare alleles' },
    ],
    value  => 'yes',
    select => 'select',
  });

  ## SIFT, PolyPhen, etc
  my $extra_fieldset = $form->add_fieldset({'class' => '_stt_extra', 'no_required_notes' => 1});
  $extra_fieldset->legend('Extra output options');

  $extra_fieldset->add_field({
    type  => 'CheckBox',
    name  => "exon_intron",
    label => "Exon and intron numbers",
    value => 'yes',
    selected => 0
  });

  $extra_fieldset->add_field({
    type  => 'CheckBox',
    name  => "domains",
    label => "Protein domains",
    value => 'yes',
    selected => 0
  });

  $extra_fieldset->add_field({
      type  => 'CheckBox',
      name  => "regulatory",
      label => "Get regulatory region consequences",
      value => 'yes',
      selected => 1
  });

  $extra_fieldset->add_field({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'SIFT predictions',
    name   => 'sift',
    values => [
      { value => 'no',    caption => 'No'                   },
      { value => 'pred',  caption => 'Prediction only'      },
      { value => 'score', caption => 'Score only'           },
      { value => 'both',  caption => 'Prediction and score' },
    ],
    value  => 'no',
    select => 'select',
  });

  $extra_fieldset->add_field({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'PolyPhen predictions',
    name   => 'polyphen',
    values => [
      { value => 'no',    caption => 'No'                   },
      { value => 'pred',  caption => 'Prediction only'      },
      { value => 'score', caption => 'Score only'           },
      { value => 'both',  caption => 'Prediction and score' },
    ],
    value  => 'no',
    select => 'select',
  });

  $html .= $form->render;
  $html .= '</div>';

  return $html;
}

1; 
