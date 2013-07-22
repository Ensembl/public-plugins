package EnsEMBL::Web::Component::Tools::VEPInputForm;

use strict;
use warnings;
no warnings 'uninitialized';


use base qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  my $html;

  #my $form = $self->modal_form('select', '/Tools/Submit');
  my $form = $self->new_form({
    id     => 'vep_input',
    action => '/Tools/Submit',
    method =>  'post',
    class  => 'blast',
    validate => 0,
    enctype => 'multipart/form-data'
  });
  
  # analysis type
  $form->add_element(
    type    => 'Hidden',
    name    => 'analysis',
    value   => 'VEP',
  );

  ## Species now set automatically for the page you are on
  my $input_fieldset = $form->add_fieldset({'class' => '_stt_input', 'no_required_notes' => 1});
  $self->_build_input($input_fieldset);
  
  my $output_fieldset = $form->add_fieldset();
  $output_fieldset->legend('Output options');

  ### Advanced config options ###
  my @sections = (
    {
      id => 'identifiers',
      title => 'Identifiers and frequency data',
      caption => 'Additional identifiers for genes, transcripts and variants; frequency data'
    },
    {
      id => 'extra',
      title => 'Extra options',
      caption => 'e.g. SIFT, PolyPhen and regulatory data'
    },
    {
      id => 'filters',
      title => 'Filtering options',
      caption => 'Pre-filter results by frequency or consequence type'
    }
  );
  
  foreach my $section(@sections) {
    my $show    = $hub->get_cookie_value('toggle_vep'.$section->{id}) eq 'open' || 0;
    my $style   = $show ? '' : 'display:none';
    
    my $configuration = $form->dom->create_element('div', {
      class       => 'config',
      #style       => 'display: inline;',
      children    => [{
        node_name   => 'a',
        rel         => 'vep'.$section->{id},
        class       => ['toggle', 'set_cookie', $show ? 'open' : 'closed'],
        href        => '#vep'.$section->{id},
        title       => $section->{caption},
        inner_HTML  => $section->{title}
      },
      {
        node_name   => 'span',
        style => 'float:right; color: grey; font-style: italic',
        inner_HTML => $section->{caption}
      }]
    });
  
    $form->append_child($configuration);
    
    my $div = $form->dom->create_element('div', {class => 'vep'.$section->{id}});
    
    my $fieldset = $form->add_fieldset;
    $fieldset->set_attributes({ id => 'vep'.$section->{id}, 'class' => ['config', 'toggleable', $show ? () : 'hidden']});
    
    my $method = '_build_'.$section->{id};
    $self->$method($fieldset);
    
    # append bits to page DOM structure
    $div->append_child($fieldset);
    $form->append_child($div);
    $form->append_child($form->dom->create_element('br'));
  }
  
  $html .= '<h2>New VEP job:</h2><input type="hidden" class="panel_type" value="VEPForm" />';
  $html .= '<div style="width:800px">'.$form->render.'</div>';
  
  return $html;
}

sub _build_input {
  my ($self, $input_fieldset) = @_;
  my $hub = $self->hub;

  $input_fieldset->legend('Input');
  my @species;

  my $current_species = $hub->species;
  foreach my $sp ($hub->species_defs->valid_species) {
    push @species, {'value' => $sp, 'caption' => $hub->species_defs->species_label($sp, 1).': '.$hub->species_defs->get_config($sp, 'ASSEMBLY_NAME')};
  }
  @species = sort {$a->{'caption'} cmp $b->{'caption'}} @species;

  $input_fieldset->add_field({
      'type'    => 'DropDown',
      'name'    => 'species',
      'label'   => "Species",
      'values'  => \@species,
      'value'   => $current_species,
      'select'  => 'select',
      'width'   => '300px',
      'class'   => '_stt'
  });

  ## Show appropriate example for selected format
  ## TODO - get value from previous dropdown via JS
  my %example = (
    'ensembl' =>  qq(1  881907  881906  -/C  +
5  140532  140532  T/C  +
1  160283  47136   DUP),
    'vcf'     => qq(1  881906  var1  A  AC  .  .  .
5  140532  var2  T  C  .  .  .
1  1385015 sv2   .  <DEL>  .  .  SVTYPE=DEL;END=1387562  .),
    'pileup'  => qq(chr5  881906  T  C),
    'id'      => qq(rs699
rs144678492
COSM354157),
    'hgvs'    => qq(ENST00000207771.3:c.344+626A>T
ENST00000471631.1:c.28_33delTCGCGG),
  );
  my $format = 'ensembl';

  $input_fieldset->add_field({ type => 'String', name => 'name', label => 'Name for this data (optional)' });

  $input_fieldset->add_field({
      'type'    => 'DropDown',
      'name'    => 'format',
      'label'   => 'Input file format (<a href="/info/docs/variation/vep/vep_formats.html#input" target="_blank">details</a>)',
      'values'  => [
        { value => 'ensembl', caption => 'Ensembl default'     },
        { value => 'vcf',     caption => 'VCF'                 },
        { value => 'pileup',  caption => 'Pileup'              },
        { value => 'id',      caption => 'Variant identifiers' },
        { value => 'hgvs',    caption => 'HGVS notations'      },
      ],
      'value'   => 'ensembl',
      'select'  => 'select',
      'class'   => '_stt'
  });
  
  my $first = 1;
  for my $tmp_format(qw(ensembl vcf pileup id hgvs)) {
    my $div = $input_fieldset->dom->create_element('div', {class => '_stt_'.$tmp_format});
    
    $div->append_child($input_fieldset->add_field({
      class => 'select_on_focus _stt_'.$tmp_format,
      type => 'Text',
      name => 'text_'.$tmp_format,
      value => $example{$tmp_format},
      label => 'Either paste data'
    }));
    
    $input_fieldset->append_child($div);
    $first = 0;
  }
  
  $input_fieldset->add_field({ type => 'File', name => 'file', label => 'Or upload file '.$self->helptip("File uploads are limited to 5MB in size. Files may be compressed using gzip or zip")});
  $input_fieldset->add_field({ type => 'URL',  name => 'url',  label => 'Or provide file URL', size => 30, class => 'url' });

  ## TODO - need to find out how to list a user's files
  #my $userdata = [];
  #$input_fieldset->add_field({
  #    'type'    => 'DropDown',
  #    'name'    => 'userdata',
  #    'label'   => "or previously select uploaded file",
  #    'values'  => $userdata,
  #    'select'  => 'select',
  #});
  
  
  # have otherfeatures?
  foreach my $sp ($hub->species_defs->valid_species) {
    if($hub->species_defs->get_config($sp, 'databases')->{'DATABASE_OTHERFEATURES'}) {
      my $div = $input_fieldset->dom->create_element('div', {class => '_stt_'.$sp});

      $div->append_child($input_fieldset->add_field({
          'type'    => 'Radiolist',
          'name'    => 'core_type_'.$sp,
          'label'   => "Transcript database to use ".$self->helptip("Select RefSeq to use the otherfeatures transcript database, which contains basic aligned RefSeq transcript sequences in place of complete Ensembl transcript models"),
          'values'  => [
            { value => 'core',          caption => 'Ensembl transcripts'          },
            { value => 'refseq', caption => 'RefSeq and other transcripts' },
          ],
          'value'   => 'core',
          'select'  => 'select'
      }));
      
      $input_fieldset->append_child($div);
    }
  }

  $input_fieldset->add_field({
    type    => 'Submit',
    name    => 'submit_vep',
    value   => 'Run >',
    class   => 'submit_vep',
  });
  
  $input_fieldset->append_child($input_fieldset->dom->create_element('hr'));
}

sub _build_filters {
  my ($self, $filter_fieldset) = @_;

  #$filter_fieldset->legend('Filters');
  
  my $human_div = $filter_fieldset->dom->create_element('div', {class => '_stt_Homo_sapiens'});
  $filter_fieldset->append_child($human_div);

  $human_div->append_child($filter_fieldset->add_field({
    'type'    => 'Radiolist',
    'name'    => 'frequency',
    'label'   => 'By frequency '.$self->helptip("Exclude common variants to remove input variants that overlap with known variants that have a minor allele frequency greater than 1% in the 1000 Genomes Phase 1 combined population. Use advanced filtering to change the population, frequency threshold and other parameters"),
    'values'  => [
      { value => 'no',        caption => 'No filtering' },
      { value => 'common',    caption => 'Exclude common variants' },
      { value => 'advanced',  caption => 'Advanced filtering' },
    ],
    'value'   => 'no',
    'select'  => 'select',
    'class'   => '_stt',
  }));
  
  my $freq_filt_div = $filter_fieldset->dom->create_element('div', {class => '_stt_advanced'});
  $human_div->append_child($freq_filt_div);
  
  $freq_filt_div->append_child($filter_fieldset->add_field({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'Filter',
    name   => 'freq_filter',
    values => [
      { value => 'exclude', caption => 'Exclude' },
    {  value => 'include', caption => 'Include only' },
    ],
    value  => 'exclude',
    select => 'select',
  }));

  $freq_filt_div->append_child($filter_fieldset->add_field({
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
  }));

  $freq_filt_div->append_child($filter_fieldset->add_field({
    type  => 'String',
    name  => 'freq_freq',
    value => '0.01',
    max   => 1,
  }));

  $freq_filt_div->append_child($filter_fieldset->add_field({
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
      { value => 'esp_aa',  caption => 'in ESP African-American population'        },
      { value => 'esp_ea',  caption => 'in ESP European-American population'       },
      #{ value => '-',       caption => '-----'                                     },
      #{ value => '1kg_asw', caption => 'in 1KG ASW population'                     },
      #{ value => '1kg_ceu', caption => 'in 1KG CEU population'                     },
      #{ value => '1kg_chb', caption => 'in 1KG CHB population'                     },
      #{ value => '1kg_chs', caption => 'in 1KG CHS population'                     },
      #{ value => '1kg_clm', caption => 'in 1KG CLM population'                     },
      #{ value => '1kg_fin', caption => 'in 1KG FIN population'                     },
      #{ value => '1kg_gbr', caption => 'in 1KG GBR population'                     },
      #{ value => '1kg_ibs', caption => 'in 1KG IBS population'                     },
      #{ value => '1kg_jpt', caption => 'in 1KG JPT population'                     },
      #{ value => '1kg_lwk', caption => 'in 1KG LWK population'                     },
      #{ value => '1kg_mxl', caption => 'in 1KG MXL population'                     },
      #{ value => '1kg_pur', caption => 'in 1KG PUR population'                     },
      #{ value => '1kg_tsi', caption => 'in 1KG TSI population'                     },
      #{ value => '1kg_yri', caption => 'in 1KG YRI population'                     },
      #{ value => '-',       caption => '-----'                                     },
      #{ value => 'hap_asw', caption => 'in HapMap ASW'                             },
      #{ value => 'hap_ceu', caption => 'in HapMap CEU'                             },
      #{ value => 'hap_chb', caption => 'in HapMap CHB'                             },
      #{ value => 'hap_chd', caption => 'in HapMap CHD'                             },
      #{ value => 'hap_gih', caption => 'in HapMap GIH'                             },
      #{ value => 'hap_jpt', caption => 'in HapMap JPT'                             },
      #{ value => 'hap_lwk', caption => 'in HapMap LWK'                             },
      #{ value => 'hap_mex', caption => 'in HapMap MEX'                             },
      #{ value => 'hap_mkk', caption => 'in HapMap MKK'                             },
      #{ value => 'hap_tsi', caption => 'in HapMap TSI'                             },
      #{ value => 'hap_yri', caption => 'in HapMap YRI'                             },
      #{ value => 'hap',     caption => 'in any HapMap population'                  },
      #{ value => '-',       caption => '-----'                                     },
      #{ value => 'any',     caption => 'any 1KG phase 1 or HapMap population'      },
    ],
    value  => '1kg_all',
    select => 'select',
    #notes   => '<strong>NB:</strong> Enabling advanced frequency filtering may be slow for large datasets',
  }));
  
  $filter_fieldset->add_field({
    type  => 'CheckBox',
    name  => "coding_only",
    label => 'Return results for variants in coding regions only '.$self->helptip("Exclude results in intronic and intergenic regions"),
    value => 'yes',
  });
  
  $filter_fieldset->add_field({
      'type'    => 'DropDown',
      'name'    => 'summary',
      'label'   => "Restrict results ".$self->helptip("Restrict results by severity of consequence; note that consequence ranks are determined subjectively by Ensembl"),
      'values'  => [
        { value => 'no',          caption => 'Show all results' },
        { value => 'per_gene',    caption => 'Show most severe per gene' },
        { value => 'summary',     caption => 'Show only list of consequences per variant' },
        { value => 'most_severe', caption => 'Show most severe per variant' },
      ],
      'value'   => 'no',
      'select'  => 'select',
      'notes'   => '<strong>NB:</strong> Restricting results may exclude biologically important data!',
    });
}


sub _build_identifiers {
  my ($self, $ident_fieldset) = @_;

  #$ident_fieldset->legend('Identifiers');

  $ident_fieldset->add_field({
    type  => 'CheckBox',
    name  => "hgnc",
    label => 'Gene symbol '.$self->helptip("Report the gene symbol (e.g. HGNC)"),
    value => 'yes',
    checked => 1
  });

  $ident_fieldset->add_field({
    type  => 'CheckBox',
    name  => "ccds",
    label => 'CCDS '.$self->helptip("Report the Consensus CDS identifier where applicable"),
    value => 'yes',
    checked => 0
  });

  $ident_fieldset->add_field({
    type  => 'CheckBox',
    name  => "protein",
    label => 'Protein '.$self->helptip("Report the Ensembl protein identifier"),
    value => 'yes',
    checked => 0
  });

  $ident_fieldset->add_field({
    type  => 'CheckBox',
    name  => "hgvs",
    label => 'HGVS '.$self->helptip("Report HGVSc (coding sequence) and HGVSp (protein) notations for your variants"),
    value => 'yes',
    checked => 0
  });
  
  my $hub = $self->hub;
  
  # have variants?
  foreach my $sp ($hub->species_defs->valid_species) {
    if($hub->species_defs->get_config($sp, 'databases')->{'DATABASE_VARIATION'}) {
      my $div = $ident_fieldset->dom->create_element('div', {class => '_stt_'.$sp});
      
      $div->append_child($ident_fieldset->add_field({
        type   => 'DropDown',
        label  => 'Find co-located known variants '.$self->helptip("Report known variants from the Ensembl Variation database that are co-located with input. Use  \'compare alleles\' to only report co-located variants where none of the input variant's alleles are novel"),
        name   => 'check_existing_'.$sp,
        values => [
          { value => 'no',     caption => 'No'                      },
          { value => 'yes',    caption => 'Yes'                     },
          { value => 'allele', caption => 'Yes and compare alleles' },
        ],
        value  => 'yes',
        select => 'select',
        class  => '_stt'
      }));
      
      # add frequency fields
      if($sp eq 'Homo_sapiens') {
        foreach(qw(yes allele)) {
          
          my $freq_div = $ident_fieldset->dom->create_element('div', {class => '_stt_'.$_});
          
          $freq_div->append_child($ident_fieldset->add_notes('<hr><span style="color: #3366bb; font-weight: bold">Frequency data for co-located variants</span>'));
          
          $freq_div->append_child($ident_fieldset->add_field({
            type  => 'CheckBox',
            name  => "gmaf_".$_,
            label => '1000 Genomes global minor allele frequency '.$self->helptip("Report the minor allele frequency for the combined 1000 Genomes Project phase 1 population"),
            value => 'yes',
            checked => 1
          }));
          
          $freq_div->append_child($ident_fieldset->add_field({
            type  => 'CheckBox',
            name  => "maf_1kg_".$_,
            label => '1000 Genomes continental minor allele frequencies '.$self->helptip("Report the minor allele frequencies for the combined 1000 Genomes Project phase 1 continental populations - AFR (African), AMR (American), ASN (Asian) and EUR (European)"),
            value => 'yes',
            checked => 0
          }));
          
          $freq_div->append_child($ident_fieldset->add_field({
            type  => 'CheckBox',
            name  => "maf_esp_".$_,
            label => 'ESP minor allele frequencies '.$self->helptip("Report the minor allele frequencies for the NHLBI Exome Sequencing Project populations - AA (African American) and EA (European American)"),
            value => 'yes',
            checked => 0
          }));
          
          $div->append_child($freq_div);
        }
      }
      
      $ident_fieldset->append_child($div);;
    }
  }
}

sub _build_extra {
  my ($self, $extra_fieldset) = @_;
  my $hub = $self->hub;

  #$extra_fieldset->legend('Extra output options');
  $extra_fieldset->add_field({
    type  => 'CheckBox',
    name  => "numbers",
    label => 'Exon and intron numbers '.$self->helptip("For variants that fall in the exon or intron, report the exon or intron number as NUMBER / TOTAL"),
    value => 'yes',
    checked => 0
  });

  $extra_fieldset->add_field({
    type  => 'CheckBox',
    name  => "domains",
    label => 'Protein domains '.$self->helptip("Report overlapping protein domains from Pfam, Prosite and InterPro"),
    value => 'yes',
    checked => 0
  });

  $extra_fieldset->add_field({
    type  => 'CheckBox',
    name  => "biotype",
    label => 'Transcript biotype '.$self->helptip("Report the biotype of overlapped transcripts, e.g. protein_coding, miRNA, psuedogene"),
    value => 'yes',
    checked => 1
  });
  
  # species-specific stuff
  foreach my $sp ($hub->species_defs->valid_species) {
    
    # regulatory
    if($hub->species_defs->get_config($sp, 'REGULATORY_BUILD')) {
      my $div = $extra_fieldset->dom->create_element('div', {class => '_stt_'.$sp});
      
      $div->append_child($extra_fieldset->add_field({
        type  => 'CheckBox',
        name  => "regulatory_".$sp,
        label => 'Get regulatory region consequences '.$self->helptip("Get consequences for variants that overlap regulatory features and transcription factor binding motifs"),
        value => 'yes',
        checked => 1
      }));
      
      $extra_fieldset->append_child($div);
      
      #my $cta = $config->{RegulatoryFeature_adaptor}->db->get_CellTypeAdaptor();
      #$cls = join ",", map {$_->name} @{$cta->fetch_all};
    }
    
    # sift?
    if($hub->species_defs->get_config($sp, 'databases')->{'DATABASE_VARIATION'}->{'SIFT'}) {
      my $div = $extra_fieldset->dom->create_element('div', {class => '_stt_'.$sp});
      
      $div->append_child($extra_fieldset->add_field({
        type   => 'DropDown',
        select =>, 'select',
        label  => 'SIFT predictions '.$self->helptip("Report SIFT scores and/or predictions for missense variants. SIFT is an algorithm to predict whether an amino acid substitution is likely to affect protein function"),
        name   => 'sift_'.$sp,
        values => [
          { value => 'no',    caption => 'No'                   },
          { value => 'both',  caption => 'Prediction and score' },
          { value => 'pred',  caption => 'Prediction only'      },
          { value => 'score', caption => 'Score only'           },
        ],
        value  => 'both',
        select => 'select',
      }));
      
      $extra_fieldset->append_child($div);
    }
    
    # polyphen?
    if($hub->species_defs->get_config($sp, 'databases')->{'DATABASE_VARIATION'}->{'POLYPHEN'}) {
      my $div = $extra_fieldset->dom->create_element('div', {class => '_stt_'.$sp});
      
      $div->append_child($extra_fieldset->add_field({
        type   => 'DropDown',
        select =>, 'select',
        label  => 'PolyPhen predictions '.$self->helptip("Report PolyPhen scores and/or predictions for missense variants. PolyPhen is an algorithm to predict whether an amino acid substitution is likely to affect protein function"),
        name   => 'polyphen_'.$sp,
        values => [
          { value => 'no',    caption => 'No'                   },
          { value => 'both',  caption => 'Prediction and score' },
          { value => 'pred',  caption => 'Prediction only'      },
          { value => 'score', caption => 'Score only'           },
        ],
        value  => 'both',
        select => 'select',
      }));
      
      $extra_fieldset->append_child($div);
    }
  }
}

1; 
