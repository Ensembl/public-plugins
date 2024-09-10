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

package EnsEMBL::Web::Component::Tools::VEP::Results;

use strict;
use warnings;

use URI::Escape qw(uri_unescape);
use HTML::Entities qw(encode_entities);
use POSIX qw(ceil);
use Bio::EnsEMBL::Variation::Utils::Constants qw(%OVERLAP_CONSEQUENCES);
use Bio::EnsEMBL::VEP::Constants qw(%FIELD_DESCRIPTIONS);
use EnsEMBL::Web::Utils::FormatText qw(helptip);
use EnsEMBL::Web::Utils::Variation qw(render_sift_polyphen);
use EnsEMBL::Web::Component::Tools::NewJobButton;
use EnsEMBL::Web::Utils::Variation qw(display_items_list);

use parent qw(EnsEMBL::Web::Component::Tools::VEP);

our $MAX_FILTERS = 50;

our %PROTEIN_DOMAIN_LABELS = (
  'CDD'                 => 'CDD',
  'Gene3D'              => 'GENE3D',
  'PANTHER'             => 'PANTHERDB',
  'Pfam'                => 'PFAM',
  'Prints'              => 'PRINTS',
  'PROSITE_profiles'    => 'PROSITE_PROFILES',
  'PROSITE_patterns'    => 'PROSITE_PATTERNS',
  'SMART'               => 'SMART',
  'Superfamily'         => 'SUPERFAMILY',
  'TIGRFAM'             => 'TIGRFAM',
  'PIRSF'               => 'PIRSF',
  'HAMAP'               => 'HAMAP',
  'SFLD'                => 'SFLD'
);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $object  = $self->object;
  my $ticket  = $object->get_requested_ticket;
  my $job     = $ticket ? $ticket->job->[0] : undef;

  return '' if !$job || $job->status ne 'done';

  my $job_data  = $job->job_data;
  my $species   = $job->species;
  my @warnings  = grep { $_->data && ($_->data->{'type'} || '') eq 'VEPWarning' } @{$job->job_message};

  # this method reconstitutes the Tmpfile objects from the filenames
  my $output_file_obj = $object->result_files->{'output_file'};

  # get all params
  my %params = map { $_ eq 'update_panel' ? () : ($_ => $hub->param($_)) } $hub->param;

  my $html = '';
  my $ticket_name = $object->parse_url_param->{'ticket_name'};

  # get params
  my $size  = $params{'size'}   || 5;
  my $from  = $params{'from'}   || 1;
  my $to    = $params{'to'};
  my $match = $params{'match'}  || 'and';

  if (defined $to) {
    $size = $to - $from + 1;
  } else {
    $to = $from + $size - 1;
  }

  # define max filters
  my $filter_string = '';
  my $location      = '';

  # construct filter string
  for (1..$MAX_FILTERS) {
    if ($params{"field$_"}) {

      if ($params{"field$_"} eq 'Location') {
        $location .= ' '.$params{"value$_"};
      } else {
        my ($field, $operator) = ($params{"field$_"}, $params{"operator$_"});

        # allow for special case where value has not been set ("defined" on the web form)
        if(($params{"value$_"} // '') eq '' ? 1 : 0) {

          # we want to do e.g. "not field" if web form was "field is not defined"
          if($operator eq 'ne') {
            $filter_string .=
              ($filter_string ? " $match "  : '').
              "not $field";
          }
          # otherwise we want e.g. "field" if web form was "field is defined"
          else {
            $filter_string .=
              ($filter_string ? " $match " : '').
              "$field";
            # User upload fields also result in empty 'value'
            if ($params{"value_dd$_"}) {
              $filter_string .= ' in '.$params{"value_dd$_"};
            } 
          }
        }

        # value has been set by user
        else {
          $filter_string .= sprintf('%s%s %s %s',
            ($filter_string ? " $match " : ''),
            $field,
            $operator,
            $operator eq 'in' ? $params{"value_dd$_"} : $params{"value$_"}
          );
        }
      }
    }
  }

  $filter_string  =~ s/^\s+//g;
  $location       =~ s/^\s+//g;

  # READ DATA
  ###########

  my %content_args = (
    from      => $from,
    to        => $to,
    filter    => $filter_string,
    location  => $location
  );

  my ($header_hash, $rows, $line_count) = @{$output_file_obj->content_parsed(\%content_args)};

  my $headers = $header_hash->{'combined'};
  my $header_extra_descriptions = $header_hash->{'descriptions'} || {};

  my $custom_config_descriptions = {};
  my $custom_configs = $sd->multi_val('ENSEMBL_VEP_CUSTOM_CONFIG');
  foreach my $cc (@{ $custom_configs }){
    my $idx = 0;
    foreach (@{ $cc->{params}->{helptips} }) {
      my $c_short_name = $cc->{params}->{short_name};
      my $c_field = $cc->{params}->{fields}->[$idx];
      $custom_config_descriptions->{$c_short_name . '_' . $c_field} = $_;
      $idx++;
    }
  }

  # Overwrite DisGeNET header description
  # Description example: "Variant-Disease-PMID associations from the DisGeNET database. The output includes 
  #   the PMID of the publication reporting the Variant-Disease association, DisGeNET score for the Variant-Disease association, 
  #   name of associated disease. Each value is separated by ':'"
  # In Web VEP, the values are not separated by ':' and therefore remove it from the description.
  if(exists $header_extra_descriptions->{'DisGeNET'}) {
    $header_extra_descriptions->{'DisGeNET'} =~ s/ Each value is separated.*//;
  }

  # Overwrite header description
  for (keys %{$header_extra_descriptions}) {
    # remove filename from specific plugins
    if ($_ =~ /^MaveDB/ || /^OpenTargets/ || /^am_/) {
      $header_extra_descriptions->{$_} =~ s/; .*//;
    } elsif ($_ eq 'PARALOGUE_REGIONS') {
      $header_extra_descriptions->{$_} =~ s/ \(.*//;
      $header_extra_descriptions->{$_} .= '</br><b>Coverage:</b> percentage of peptide alignment</br><b>Positivity:</b> percentage of similarity between both homologues';

      my ($source, $version) = $header_extra_descriptions->{PARALOGUE_VARIANTS} =~ /.*_(.*)_(.*)\..*.gz/;
      $header_extra_descriptions->{$_} = "Genomic location of paralogue regions and corresponding variants from $source $version in paralogue locations";
    }
  }

  my $actual_to = $from - 1 + ($line_count || 0);
  my $row_count = scalar @$rows;

  # Remove default columns if the options haven't been selected in the form
  # (the columns will be empty anyway)
  my %skip_colums;

  if (!$job_data->{'hgvs'}) {
    $skip_colums{'HGVSc'} = 1;
    $skip_colums{'HGVSp'} = 1;
  }

  $skip_colums{"5UTR_annotation"} = 1; # UTRAnnotator
  $skip_colums{'Geno2MP_URL'} = 1; # URL added to Geno2MP HPO counts column
  $skip_colums{'OpenTargets_geneId'} = 1; # gene ID added to Open Targets L2G column
  $skip_colums{'PARALOGUE_VARIANTS'} = 1; # info added to PARALOGUE_REGIONS column

  if (%skip_colums) {
    my @tmp_headers;
    foreach my $header (@$headers) {
      push @tmp_headers, $header if (!$skip_colums{$header});
    }
    $headers = \@tmp_headers;
  }

  # niceify for table
  my %header_titles = (
    'ID'                  	=> 'Uploaded variant',
    'MOTIF_NAME'          	=> 'Motif name',
    'MOTIF_POS'           	=> 'Motif position',
    'MOTIF_SCORE_CHANGE'  	=> 'Motif score change',
    'DISTANCE'            	=> 'Distance to transcript',
    'EXON'                	=> 'Exon',
    'INTRON'              	=> 'Intron',
    'CLIN_SIG'            	=> 'Clinical significance',
    'BIOTYPE'             	=> 'Biotype',
    'PUBMED'              	=> 'Pubmed',
    'HIGH_INF_POS'        	=> 'High info position',
    'CELL_TYPE'           	=> 'Cell type',
    'CANONICAL'           	=> 'Canonical',
    'SYMBOL'              	=> 'Symbol',
    'SYMBOL_SOURCE'       	=> 'Symbol source',
    'DOMAINS'             	=> 'Protein matches',
    'STRAND'              	=> 'Feature strand',
    'TSL'                 	=> 'Transcript support level',
    'SOMATIC'             	=> 'Somatic status',
    'PICK'                	=> 'Selected annotation',
    'SOURCE'              	=> 'Transcript source',
    'IMPACT'              	=> 'Impact',
    'PHENO'               	=> 'Phenotype or disease',
    'Existing_variation'  	=> 'Existing variant',
    'REFSEQ_MATCH'        	=> 'RefSeq match',
    'HGVS_OFFSET'         	=> 'HGVS offset',
    'PHENOTYPES'         	=> 'Associated phenotypes',
    'DisGeNET'            	=> 'DisGeNET',
    'Mastermind_MMID3'    	=> 'Mastermind URL',
    'VAR_SYNONYMS'        	=> 'Variant synonyms',
    'IntAct_ap_ac'	  	=> 'IntAct affected protein AC',
    'IntAct_feature_ac'		=> 'IntAct feature AC',
    'IntAct_interaction_ac'	=> 'IntAct interaction AC',
    'IntAct_pmid'	 	=> 'IntAct pubmed',
    'GO'                        => 'GO terms',
    'MaveDB_nt'                 => 'MaveDB nucleotide change',
    'MaveDB_pro'                => 'MaveDB protein change',
    'MaveDB_score'              => 'MaveDB score',
    'MaveDB_urn'                => 'MaveDB URN',
    'PARALOGUE_REGIONS'         => 'Paralogue regions and ClinVar variants',
    'PARALOGUE_VARIANTS'        => 'Paralogue variants',
    'OpenTargets_l2g'           => 'Open Targets Genetics L2G',
    'am_pathogenicity'          => 'AlphaMissense pathogenicity score',
    'am_class'                  => 'AlphaMissense classification',
  );
  for (grep {/\_/} @$headers) {
    $header_titles{$_} ||= $_ =~ s/\_/ /gr;
  }

  # hash for storing seen IDs, used to link to BioMart
  my %seen_ids;

  # linkify row content
  my %display_column = map { $_ => 0 } @$headers;
  $display_column{'ALLELE'} = 1 if (defined $display_column{'ALLELE'});
  my $row_id = 0;
  foreach my $row (@$rows) {

    # store IDs
    push @{$seen_ids{'vars'}}, $row->{'Existing_variation'} if defined $row->{'Existing_variation'} && $row->{'Existing_variation'} =~ /\w+/;
    push @{$seen_ids{'genes'}}, $row->{'Gene'} if defined $row->{'Gene'} && $row->{'Gene'} =~ /\w+/;

    my $gene_id     = $row->{'Gene'};
    my $feature_id  = $row->{'Feature'};
    my $consequence = $row->{'Consequence'};
    my $location    = $row->{'Location'};

    # linkify content
    foreach my $header (@$headers) {
      $row->{$header} = $self->linkify($header, $row->{$header}, $species, $job_data);
      if ($row->{$header} && $row->{$header} ne '' && $row->{$header} ne '-') {
        if ($header eq 'PUBMED') {
          $row->{$header} = $self->get_items_in_list($row_id, 'pubmed', 'PubMed IDs', $row->{$header}, $species);
        }
        elsif ($header eq 'PHENOTYPES'){
          $row->{$header} = $self->get_items_in_list($row_id, 'phenotype', 'Phenotype associations', $row->{$header}, $species, 3);
        }
        elsif ($header eq 'DisGeNET'){
          $row->{$header} = $self->get_items_in_list($row_id, 'disgenet', 'DisGeNET', $row->{$header}, $species);
        }
        elsif ($header eq 'Mastermind_MMID3'){
          $row->{$header} = $self->get_items_in_list($row_id, 'mastermind_mmid3', 'Mastermind URL', $row->{$header}, $species);
        }
        elsif ($header eq 'VAR_SYNONYMS'){
          $row->{$header} = $self->get_items_in_list($row_id, 'variant_synonyms', 'Variant synonyms', $row->{$header}, $species);
        }
        elsif ($header eq 'DOMAINS') {
          $self->render_protein_matches(
            $row,
            $row_id,
            $gene_id, # note that $row->{'Gene'} is no longer reliable, since it was mutated by linkify above
            $feature_id,
            $consequence,
            $species
          );
        }
        elsif ($header eq 'IntAct_ap_ac'){
          $row->{$header} = $self->get_items_in_list($row_id, 'IntAct_ap_ac', 'IntAct affected protein accession IDs', $row->{$header}, $species);
        }
        elsif ($header eq 'IntAct_feature_ac'){
          $row->{$header} = $self->get_items_in_list($row_id, 'IntAct_feature_ac', 'IntAct feature accession IDs', $row->{$header}, $species);
        }
        elsif ($header eq 'IntAct_feature_annotation'){
          $row->{$header} = $self->get_items_in_list($row_id, 'IntAct_feature_annotation', 'IntAct feature annotations', $row->{$header}, $species, 3);
        }
        elsif ($header eq 'IntAct_feature_short_label'){
          $row->{$header} = $self->get_items_in_list($row_id, 'IntAct_feature_short_label', 'IntAct feature short labels', $row->{$header}, $species, 3);
        }
        elsif ($header eq 'IntAct_feature_type'){
          $row->{$header} = $self->get_items_in_list($row_id, 'IntAct_feature_type', 'IntAct feature types', $row->{$header}, $species, 3);
        }
        elsif ($header eq 'IntAct_interaction_ac'){
          $row->{$header} = $self->get_items_in_list($row_id, 'IntAct_interaction_ac', 'IntAct interaction accession IDs', $row->{$header}, $species);
        }
        elsif ($header eq 'IntAct_interaction_participants'){
          $row->{$header} = $self->get_items_in_list($row_id, 'IntAct_interaction_participants', 'IntAct interaction participants', $row->{$header}, $species, 2);
        }
        elsif ($header eq 'IntAct_pmid'){
          $row->{$header} = $self->get_items_in_list($row_id, 'IntAct_pmid', 'IntAct PubMed IDs', $row->{$header}, $species);
        }
        elsif ($header eq 'GO'){
          $row->{$header} = $self->get_items_in_list($row_id, 'GO', 'GO terms', $row->{$header}, $species);
        }
        elsif ($header eq 'MaveDB_nt'){
          $row->{$header} = $self->get_items_in_list($row_id, 'MaveDB_nt', 'MaveDB nucleotide change', $row->{$header}, $species);
        }
        elsif ($header eq 'MaveDB_pro'){
          $row->{$header} = $self->get_items_in_list($row_id, 'MaveDB_pro', 'MaveDB protein change', $row->{$header}, $species);
        }
        elsif ($header eq 'MaveDB_score'){
          $row->{$header} = $self->get_items_in_list($row_id, 'MaveDB_score', 'MaveDB score', $row->{$header}, $species);
        }
        elsif ($header eq 'MaveDB_urn'){
          $row->{$header} = $self->get_items_in_list($row_id, 'MaveDB_urn', 'MaveDB URN', $row->{$header}, $species);
        }
        elsif ($header eq 'PARALOGUE_REGIONS'){
          # prepare paralogue variants
          my $paralogue_vars = [];
          for ( split(/,/, $row->{PARALOGUE_VARIANTS}) ) {
            my $var = {};
            @$var{('id', 'alleles', 'clnsig', 'chr', 'start')} = split /:/, $_;
            $var->{'clnsig'} =~ s/_/ /g;

            # prepare URL to ClinVar ID
            $var->{item_url} = $hub->get_ExtURL_link($var->{'id'}, 'CLINVAR_VAR',
              $var->{'id'}) . " ($var->{alleles}; $var->{clnsig})";
            push @$paralogue_vars, $var;
          }

          $row->{$header} = $self->get_items_in_list($row_id, 'PARALOGUE_REGIONS', 'Paralogue regions', $row->{$header}, $species, undef, { 'gene_id' => $gene_id, 'paralogue_variants' => $paralogue_vars });
        }
        elsif ($header eq 'OpenTargets_l2g'){
          my ($chrom, $start, $end) = split /\:|\-/, $location;
          my $var = sprintf("%s_%s_%s_%s", $chrom, $start, $row->{REF_ALLELE}, $row->{Allele});

          my @geneId = split ",",  $row->{'OpenTargets_geneId'};
          my @l2g    = split ", ", $row->{$header};

          my @data;
          for my $i (0 .. $#l2g) {
            my $gene_url = $hub->get_ExtURL_link($geneId[$i], 'OPENTARGETSGENETICS_GENE', $geneId[$i]);
            push @data, sprintf("<b>%s</b>: %.6f", $gene_url, $l2g[$i]);
          }

          my $var_url = $hub->get_ExtURL_link($var, 'OPENTARGETSGENETICS_VARIANT', $var);
          $row->{$header} = $self->get_items_in_list($row_id, 'OpenTargets_l2g', 'L2G scores', join(", ", @data), $species, 5)
            . "<div class='in-table-button' style='line-height: 20px'>Variant info: " . $var_url . "</div>";
        }
        elsif ($header eq 'Geno2MP_HPO_count') {
          $row->{$header} = $self->get_items_in_list($row_id, 'Geno2MP_HPO_count', 'Geno2MP HPO count', $row->{$header}, $species, 5, $row->{'Geno2MP_URL'});
        }

        $display_column{$header} = 1 if (!$display_column{$header});
      }
      $row_id++;
    }
  }

  # Force to hide some columns by default
  foreach my $col ('IMPACT','SYMBOL_SOURCE','INTRON','DISTANCE','FLAGS','HGNC_ID','PHENO') {
    $display_column{$col} = 0;
  }
  foreach my $cc (@{ $custom_configs }){
    $display_column{$cc->{params}->{short_name}} = 0;
  }

  # extras
  my %table_sorts = (
    'Location'            => 'position_html',
    'cDNA_position'       => 'numeric',
    'CDS_position'        => 'numeric',
    'Protein_position'    => 'numeric',
    'MOTIF_POS'           => 'numeric',
    'MOTIF_SCORE_CHANGE'  => 'numeric',
    'SIFT'                => 'hidden_position',
    'PolyPhen'            => 'hidden_position',
    'AF'                  => 'numeric',
    'AFR_AF'              => 'numeric',
    'AMR_AF'              => 'numeric',
    'ASN_AF'              => 'numeric',
    'EUR_AF'              => 'numeric',
    'EAS_AF'              => 'numeric',
    'SAS_AF'              => 'numeric',
    'AA_AF'               => 'numeric',
    'EA_AF'               => 'numeric',
    'ExAC_AFR_AF'         => 'numeric',
    'ExAC_AMR_AF'         => 'numeric',
    'ExAC_Adj_AF'         => 'numeric',
    'ExAC_EAS_AF'         => 'numeric',
    'ExAC_FIN_AF'         => 'numeric',
    'ExAC_NFE_AF'         => 'numeric',
    'ExAC_OTH_AF'         => 'numeric',
    'ExAC_SAS_AF'         => 'numeric',
    'DISTANCE'            => 'numeric',    
    'EXON'                => 'hidden_position',
    'INTRON'              => 'hidden_position'
  );

  my @table_headers = map {{
    'key' => $_,
    'title' => ($header_titles{$_} || $_),
    'sort' => $table_sorts{$_} || 'string',
    'help' => $FIELD_DESCRIPTIONS{$_} || $header_extra_descriptions->{$_} || $custom_config_descriptions->{$_},
  }} @$headers;

  # properly style external links in buttons
  $html .= "
    <style>.in-table-button > a[rel='external'] {
      padding-right: 12px !important;
    }</style>";

  $html .= '<div><h3>Results preview</h3>';
  $html .= '<input type="hidden" class="panel_type" value="VEPResults" />';
  $html .= $self->_warning('Some errors occurred while running VEP', sprintf '<pre class="tools-warning">%s</pre>', join "\n", map $_->display_message, @warnings) if @warnings;

  # construct hash for autocomplete
  my $vdbc = $sd->get_config($species, 'databases')->{'DATABASE_VARIATION'};

  my %ac = (
    'Allele'        => [ 'A', 'C', 'G', 'T' ],
    'Feature_type'  => [ qw(Transcript MotifFeature RegulatoryFeature) ],
    'Consequence'   => [ keys %OVERLAP_CONSEQUENCES ],
    'IMPACT'        => [ keys %{{map {$_->impact => 1} values %OVERLAP_CONSEQUENCES}} ],
    'SIFT'          => [ map {s/ /\_/g; s/\_\-\_/\_/g; $_} @{$vdbc->{'SIFT_VALUES'}} ],
    'PolyPhen'      => [ map {s/\s/\_/g; $_} @{$vdbc->{'POLYPHEN_VALUES'}} ],
    'BIOTYPE'       => $sd->get_config($species, 'databases')->{'DATABASE_CORE'}->{'tables'}{'transcript'}{'biotypes'},
  );

  my $ac_json = encode_entities($self->jsonify(\%ac));
  $html .= qq(<input class="js_param" type="hidden" name="auto_values" value="$ac_json" />);

  # open toolbox containers div
  $html .= '<div>';

  # add toolboxes
  my $nav_html = $self->_navigation($actual_to, $filter_string || $location);

  # navigation HTML we frame here as we want to reuse it unframed after the results table
  $html .= '<div class="toolbox right-margin">';
  $html .= '<div class="toolbox-head">';
  $html .= '<img src="/i/16/eye.png" style="vertical-align:top;"> ';
  $html .= helptip('Navigation', "Navigate through the results of your VEP job. By default the results for 5 variants are displayed; note that variants may have more than one result if they overlap multiple transcripts")." <small>(per variant)</small>";
  $html .= '</div>';
  $html .= '<div style="padding:5px;">'.$nav_html.'</div>';
  $html .= '</div>';

  # these are framed within the subroutine
  my ($filter_html, $active_filters) = @{$self->_filters($headers, \%header_titles)};
  $html .= $filter_html;

  my $download_html = $self->_download(\%content_args, \%seen_ids, $species);
  $html .= $download_html;

  my $button_url = $hub->url({'function' => undef, 'expand_form' => 'true'});
  my $new_job_button = EnsEMBL::Web::Component::Tools::NewJobButton->create_button( $button_url );
  $html .= '<span class="left-margin">' . $new_job_button . '</span>';

  # close toolboxes container div
  $html .= '</div>';


  # Hide columns with no values, as well as those not shown by default
  my @hidden_columns;
  my $i = 0;
  foreach (@$headers) {
    if ($display_column{$_} == 0) {
      push @hidden_columns, $i;
    }
    $i++;
  }

  # render table
  my $data_table_options = { 
                             data_table => 1, 
                             sorting => [ 'Location asc' ], 
                             exportable => 0, 
                             data_table_config => { bLengthChange => 'false', bFilter => 'false' }, 
                             hidden_columns => \@hidden_columns || []
                           };
  my $table = $self->new_table(\@table_headers, $rows, $data_table_options); 
  $html .= $table->render || '<h3>No data</h3>';

  # repeat navigation div under table
  $html .= '<div>'.$nav_html.'</div>';

  $html .= '</div>';

  return $html;
}

sub prettify_phenotypes {
  my ($self, $entries, $species) = @_;
  my @result;

  my $hub = $self->hub;

  #unify
  my %phenotypes;
  foreach my $entry (@$entries) {
    $entry =~ tr/_/ /;
    my @parts = split('\+',$entry);
    $phenotypes{$parts[0]}{$parts[2]}{$parts[1]} = 1;
  }

  # display fromat:   # 'HYPERTENSION__ESSENTIAL+MIM_morbid+ENSG00000135744' -> HYPERTENSION ESSENTIAL(ENSG00000135744,MIM_morbid) OR  HYPERTENSION ESSENTIAL(ENSG00000135744,MIM_morbid & Orphanet & DDG2P)
  foreach my $pheno (keys %phenotypes){
    foreach my $object (keys %{$phenotypes{$pheno}}){
      # create and add links out to gene and variant phenotype pages
      my $new_obj = $object;
      if ($object =~ /ENSG*/){
        my $url = $hub->url({
          type    => 'Gene',
          action  => 'Phenotype',
          g       => $object,
          species => $species,
        });
        $new_obj = sprintf('<a href="%s">%s</a>',$url,$object);
      } elsif ($object =~ /^rs\d+/){
        my $url = $hub->url({
          type    => 'Variation',
          action  => 'Phenotype',
          v       => $object,
          species => $species
        });
        $new_obj = sprintf('<a href="%s">%s</a>',$url,$object);
      }
      push(@result, $pheno.' ('.$new_obj.",".join(' & ',keys %{$phenotypes{$pheno}{$object}}).")");
    }
  }
  return @result;
}

## NAVIGATION
#############

sub _navigation {
  my $self = shift;
  my $actual_to = shift;
  my $filter_string_or_location = shift;

  my $object = $self->object;
  my $hub = $self->hub;

  my $stats = $self->job_statistics;
  my $output_lines =
    $stats->{'General statistics'}->{'Lines of output written'} ||
    $stats->{'General statistics'}->{'Variants processed'} - $stats->{'General statistics'}->{'Variants filtered out'} ||
    0;

  # get params
  my %params = map { $_ eq 'update_panel' ? () : ($_ => $hub->param($_)) } $hub->param;
  my $size  = $params{'size'} || 5;
  my $from  = $params{'from'} || 1;
  my $to    = $params{'to'};

  my $orig_size = $size;

  if (defined $to) {
    $size = $to - $from + 1;
  } else {
    $to = $from + $size - 1;
  }

  $actual_to ||= 0;

  my $this_page   = (($from - 1) / $orig_size) + 1;
  my $page_count  = ceil($output_lines / $orig_size);
  my $showing_all = ($to - $from) == ($output_lines - 1) ? 1 : 0;

  my $html = '';

  # navigation
  unless($showing_all) {
    my $style           = 'style="vertical-align:top; height:16px; width:16px"';
    my $disabled_style  = 'style="vertical-align:top; height:16px; width:16px; opacity: 0.5;"';

    $html .= '<b>Page: </b>';

    # first
    if ($from > 1) {
      $html .= $self->reload_link(qq(<img src="/i/nav-l2.gif" $style title="First page"/>), {
        'from' => 1,
        'to'   => $orig_size,
        'size' => $orig_size,
      });
    } else {
      $html .= '<img src="/i/nav-l2.gif" '.$disabled_style.'/>';
    }

    # prev page
    if ($from > 1) {
      $html .= $self->reload_link(sprintf('<img src="/i/nav-l1.gif" %s title="Previous page"/></a>', $style), {
        'from' => $from - $orig_size,
        'to'   => $to - $orig_size,
        'size' => $orig_size,
      });
    } else {
      $html .= '<img src="/i/nav-l1.gif" '.$disabled_style.'/>';
    }

    # page indicator and count
    $html .= sprintf(
      " %i of %s ",
      $this_page,
      (
        $from == 1 && !($to <= $actual_to && $to < $output_lines) ?
        1 :
        (
          $filter_string_or_location ? 
          '<span class="ht _ht" title="Result count cannot be calculated with filters enabled">?</span>' :
          $page_count
        )
      )
    );

    # next page
    if ($to <= $actual_to && $to < $output_lines) {
      $html .= $self->reload_link(sprintf('<img src="/i/nav-r1.gif" %s title="Next page"/></a>', $style), {
        'from' => $from + $orig_size,
        'to'   => $to + $orig_size,
        'size' => $orig_size,
      });
    } else {
      $html .= '<img src="/i/nav-r1.gif" '.$disabled_style.'/>';
    }

    # last
    if ($to < $output_lines && !$filter_string_or_location) {
      $html .= $self->reload_link(qq(<img src="/i/nav-r2.gif" $style title="Last page"/></a>), {
        'from' => ($size * int($output_lines / $size)) + 1,
        'to'   => $output_lines,
        'size' => $orig_size,
      });
    } else {
      $html .= '<img src="/i/nav-r2.gif" '.$disabled_style.'/>';
    }

    $html .= '<span style="padding: 0px 10px 0px 10px; color: grey">|</span>';
  }

  # number of entries
  $html .= '<b>Show: </b> ';

  foreach my $opt_size (qw(1 5 10 50)) {
    next if $opt_size > $output_lines;

    if($orig_size eq $opt_size) {
      $html .= sprintf(' <span class="count-highlight">&nbsp;%s&nbsp;</span>', $opt_size);
    }
    else {
      $html .= ' '. $self->reload_link($opt_size, {
        'from' => $from,
        'to'   => $to + ($opt_size - $size),
        'size' => $opt_size,
      });
    }
  }

  # showing all?
  if ($showing_all) {
    $html .= ' <span class="count-highlight">&nbsp;All&nbsp;</span>';
  } else {
    my $warning = '';
    if($output_lines > 500) {
      $warning  = '<img class="_ht" src="/i/16/alert.png" style="vertical-align: top;" title="<span style=\'color: yellow; font-weight: bold;\'>WARNING</span>: table with all data may not load in your browser - use Download links instead">';
    }

    $html .=  ' ' . $self->reload_link("All$warning", {
      'from' => 1,
      'to'   => $output_lines,
      'size' => $output_lines,
   });
  }

  $html .= ' variants';
}


## FILTERS
##########

sub _filters {
  my $self = shift;
  my $headers = shift;
  my $header_titles = shift;

  my $hub = $self->hub;
  my %params = map { $_ eq 'update_panel' ? () : ($_ => $hub->param($_)) } $hub->param;
  my $match = $params{'match'}  || 'and';
  my $html = '';

  $html .= '<div class="toolbox right-margin">';
  $html .= '<div class="toolbox-head"><img src="/i/16/search.png" style="vertical-align:top;"> ';
  $html .= helptip('Filters', "Filter your results to find interesting or significant data. You can apply several filters on any category of data in your results using a range of operators, add multiple filters, and edit active filters");
  $html .= '</div>';
  $html .= '<div style="padding:0px 5px 0px 5px;">';

  my $form_url = $hub->url();
  my $ajax_url = $self->ajax_url(undef, {'update_panel' => 1, '__clear' => 1});

  my $ajax_html .= qq(<form action="#" class="_apply_filter" style="margin: 0;"><input type="hidden" name="ajax_url" value="$ajax_url" />);

  # define operators
  my @operators = (
    {'name' => 'is',  'title' => 'is'},
    {'name' => 'ne',  'title' => 'is not'},
    {'name' => 're',  'title' => 'matches'},
    {'name' => 'lt',  'title' => '<'},
    {'name' => 'gt',  'title' => '>'},
    {'name' => 'lte', 'title' => '<='},
    {'name' => 'gte', 'title' => '>='},
    {'name' => 'in',  'title' => 'in file'},
  );
  my @non_numerical = @operators[0..2];
  my %operators = map {$_->{'name'} => $_->{'title'}} @operators;

  # active filters
  my $active_filters = 0;
  my $filter_number;

  my @filter_divs;
  my @location_divs;

  my @user_files =
    sort { $b->{'timestamp'} <=> $a->{'timestamp'} }
    grep { $_->{'format'} && lc($_->{'format'}) eq 'gene_list' }
    $hub->session->get_records_data({'type' => 'upload'}), $hub->user ? $hub->user->get_records_data({'type' => 'upload'}) : ();

  my %file_display_name = map { $_->{file} => $_->{name} } @user_files;

  $html .= '<div>';
  foreach my $i (1..$MAX_FILTERS) {
    if ($params{"field$i"}) {
      my $tmp_html;

      $active_filters++;

      # filter display
      $tmp_html .= sprintf('
        <div class="filter filter_edit_%s">
          %s %s %s
          <span style="float:right; vertical-align: top;">
            <a href="#" class="filter_toggle" rel="filter_edit_%s"><img class="_ht" src="/i/16/pencil-whitebg.png" title="Edit filter"></a>
            %s
          </span>
        </div>',
        $i,
        $header_titles->{$params{"field$i"}} || $params{"field$i"},
        $operators{$params{"operator$i"}},
        $params{"operator$i"} eq 'in' ? $file_display_name{$params{"value_dd$i"}} : ($params{"value$i"} ne "" ? $params{"value$i"} : 'defined'),
        $i,
        $self->reload_link('<img class="_ht" src="/i/close.png" title="Remove filter" style="height:16px; width:16px">', {
          "field$i"       => undef,
          "operator$i"    => undef,
          "value$i"       => undef,
          "value_dd$i"    => undef,
          'update_panel'  => undef
        })
      );

      # edit filter
      $tmp_html .= qq(<div class="filter_edit_$i" style="display:none;">);
      $tmp_html .= $ajax_html;

      # field
      $tmp_html .= qq('<select class="autocomplete" name="field$i">);
      $tmp_html .= sprintf(
        '<option value="%s" %s>%s</option>',
        $_,
        $_ eq $params{"field$i"} ? 'selected="selected"' : '',
        $header_titles->{$_} || $_
      ) for @$headers;
      $tmp_html .= '</select>';

      # operator
      $tmp_html .= qq(<select name="operator$i" class="_operator_dd">);
      $tmp_html .= sprintf(
        '<option value="%s" %s>%s</option>',
        $_->{'name'},
        ($_->{'name'} eq $params{"operator$i"} ? 'selected="selected"' : ''),
        $_->{'title'}
      ) for @operators;
      $tmp_html .= '</select>';

      # value and submit
      $tmp_html .= sprintf(
        qq(<input class="autocomplete _value_switcher %s" type="text" placeholder="defined" name="value$i" value="%s" />),
        $params{"operator$i"} eq 'in' ? 'hidden' : '',
        $params{"value$i"}
      );

      # value (dropdown file selector)
      $tmp_html .= sprintf(
        '<span class="_value_switcher %s">',
        $params{"operator$i"} eq 'in' ? '' : 'hidden'
      );
      if(scalar @user_files) {
        $tmp_html .= '<select name="value_dd'.$i.'">';
        $tmp_html .= sprintf(
          '<option value="%s" %s>%s</option>',
          $_->{file},
          $_->{file} eq $params{"value_dd$i"} ? 'selected="selected"' : '',
          $_->{name}
        ) for @user_files;
        $tmp_html .= '</select>';
      }
      my $url = $hub->url({
        type   => 'UserData',
        action => 'SelectFile',
        tool   => 'VEP',
      });
      $tmp_html .= '<span class="small"> <a href="'.$url.'" class="modal_link data" rel="modal_user_data">Upload file</a> </span>';
      $tmp_html .= '</span>';

      # update/submit
      $tmp_html .= '<input value="Update" class="fbutton" type="submit" />';

      # add hidden fields
      $tmp_html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for grep {!/[a-z]$i$/i} keys %params;
      $tmp_html .= '</form>';
      $tmp_html .= qq(<div style="padding-left: 2px;"><a href="#" class="small filter_toggle" style="color:white;" rel="filter_edit_$i">Cancel</a></div>);
      $tmp_html .= '</div>';

      if($params{"field$i"} =~ /^Location/) {
        push @location_divs, $tmp_html;
      } else {
        push @filter_divs, $tmp_html;
      }
    } else {
      $filter_number ||= $i;
    }
  }

  foreach my $div (@location_divs) {
    $html .= qq(<div class="location-filter-box filter-box">$div</div>);
  }
  # $html .= '<hr style="margin:2px"/>' if scalar @location_divs && scalar @filter_divs;

  foreach my $div (@filter_divs) {
    $html .= qq(<div class="filter-box">$div</div>);
  }

  $html .= '</div>';

  if ($active_filters > 1) {
    my %logic = (
      'or'  => 'any',
      'and' => 'all',
    );

    # clear
    $html .= '<div style="float:left;">'.$ajax_html;
    $html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for grep {!/(field|operator|value|match)/} keys %params;
    $html .= '<input value="Clear filters" class="fbutton" type="submit">';
    $html .= '</form></div>';

    if(scalar @filter_divs > 1) {
      $html .= '<div style="float:right;">'.$ajax_html;
      $html .= 'Match <select name="match"">';
      $html .= sprintf('<option value="%s" %s>%s</option>', $_, ($_ eq $match ? 'selected="selected"' : ''), $logic{$_}) for sort keys %logic;
      $html .= '</select> of the above rules ';
      $html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for grep {!/match/} keys %params;
      $html .= '<input value="Update" class="fbutton" type="submit">';
      $html .= '</form></div>';
    }
  }

  # start form
  #$html .= sprintf('<div style="display:inline-block;"><form action="%s" method="get">', $form_url);
  $html .= '<div style="clear: left;">';

  # $html .= '<hr style="margin:2px"/>' if $active_filters;
  $html .= $ajax_html;

  # field
  $html .= '<select class="autocomplete right-margin" name="field'.$filter_number.'">';
  $html .= sprintf('<option value="%s">%s</option>', $_, $header_titles->{$_} || $_) for @$headers;
  $html .= '</select>';

  # operator
  $html .= '<select class="_operator_dd right-margin" name="operator'.$filter_number.'">';
  $html .= sprintf('<option value="%s" %s>%s</option>', $_->{name}, ($_->{name} eq 'is' ? 'selected="selected"' : ''), $_->{title}) for @operators;
  $html .= '</select>';

  # value (text box)
  $html .= '<input class="autocomplete _value_switcher right-margin" type="text" placeholder="defined" name="value'.$filter_number.'">';

  # value (dropdown file selector)
  $html .= '<span class="_value_switcher hidden">';
  if(scalar @user_files) {
    $html .= '<select name="value_dd'.$filter_number.'">';
    $html .= sprintf('<option value="%s">%s</option>', $_->{file}, $_->{name}) for @user_files;
    $html .= '</select>';
  }
  my $url = $hub->url({
    type   => 'UserData',
    action => 'SelectFile',
    tool   => 'VEP',
  });
  $html .= '<span class="small"> <a href="'.$url.'" class="modal_link data" rel="modal_user_data">Upload file</a> </span>';
  $html .= '</span>';

  # submit
  $html .= '<input value="Add" class="fbutton" type="submit">';

  # add hidden fields
  $html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for keys %params;
  $html .= '</form></div>';

  $html .= '</div></div>';

  return [$html, $active_filters];
}


## DOWNLOAD
###########

sub _download {
  my $self = shift;
  my $content_args = shift;
  my $seen_ids = shift;
  my $species = shift;

  my $object = $self->object;
  my $hub    = $self->hub;
  my $sd     = $hub->species_defs;

  my $html = '';

  $html .= '<div class="toolbox">';
  $html .= '<div class="toolbox-head"><img src="/i/16/download.png" style="vertical-align:top;"> Download</div><div style="padding:5px;">';

  # all
  $html .= '<div><b>All:</b><span style="float:right; margin-left:10px;">';
  $html .= sprintf(
    ' <a class="_ht" title="Download all results in %s format%s" href="%s">%s</a>',
    $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $object->download_url({ 'format' => lc $_ }), $_
  ) for qw(VCF VEP TXT);
  $html .= '</span></div>';

  # filtered
  if($content_args->{filter}) {

    $html .= '<div style="margin-top: 5px"><b>Filtered:</b><span style="float:right; margin-left:10px;">';
    $html .= sprintf(
      ' <a class="_ht" title="Download filtered results in %s format%s" href="%s">%s</a>',
      $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $object->download_url({ 'format' => lc $_, map {$_ => $content_args->{$_}} grep {!/to|from/} keys %$content_args }), $_
    ) for qw(VCF VEP TXT);
    $html .= '</span></div>';
  }


  ## BIOMART
  ##########

  if($hub->is_in_biomart) {

    # uniquify lists, retain order
    foreach my $key(keys %$seen_ids) {
      my %tmp_seen;
      my @tmp_list;

      foreach my $item(@{$seen_ids->{$key}}) {
        push @tmp_list, $item unless $tmp_seen{$item};
        $tmp_seen{$item} = 1;
      }

      $seen_ids->{$key} = \@tmp_list;
    }

    # generate mart species name
    my @split = split /\_/, $species;
    my $m_species = lc(substr($split[0], 0, 1)).$split[1];

    my $var_mart_url =
      '/biomart/martview?VIRTUALSCHEMANAME=default'.
      '&ATTRIBUTES='.
      $m_species.'_snp.default.snp.refsnp_id|'.
      $m_species.'_snp.default.snp.refsnp_source|'.
      $m_species.'_snp.default.snp.chr_name|'.
      $m_species.'_snp.default.snp.chrom_start'.
      '&FILTERS='.
      $m_species.'_snp.default.filters.snp_filter.%22'.join(",", @{$seen_ids->{vars} || []}).'%22'.
      '&VISIBLEPANEL=filterpanel';

    my $gene_mart_url =
      '/biomart/martview?VIRTUALSCHEMANAME=default'.
      '&ATTRIBUTES='.
      $m_species.'_gene_ensembl.default.feature_page.ensembl_gene_id|'.
      $m_species.'_gene_ensembl.default.feature_page.chromosome_name|'.
      $m_species.'_gene_ensembl.default.feature_page.start_position|'.
      $m_species.'_gene_ensembl.default.feature_page.end_position'.
      '&FILTERS='.
      $m_species.'_gene_ensembl.default.filters.ensembl_gene_id.%22'.join(",", @{$seen_ids->{genes} || []}).'%22'.
      '&VISIBLEPANEL=filterpanel';

    $html .= '<div style="margin-top: 5px"><b>BioMart:</b><span style="float:right; margin-left:10px;">';

    $html .= $seen_ids->{vars} ? sprintf(
      '<a class="_ht" title="Query BioMart with co-located variants in this view" rel="external" href="%s">Variants</a> ',
      $var_mart_url) : 'Variants ';

    $html .= $seen_ids->{genes} ? sprintf(
      '<a class="_ht" title="Query BioMart with genes in this view" rel="external" href="%s">Genes</a>',
      $gene_mart_url) : 'Genes ';

    $html .= '</div>';
  }

  $html .= '</div></div>';

  return $html;
}

sub linkify {
  my $self = shift;
  my $field = shift;
  my $value = shift;
  my $species = shift;
  my $job_data = shift;

  # work out core DB type
  my $db_type = 'core';
  if(my $ct = $job_data->{core_type}) {
    if($ct eq 'refseq' || ($value && $ct eq 'merged' && $value !~ /^ENS/)) {
      $db_type = 'otherfeatures';
    }
  }

  my $new_value;
  my $hub = $self->hub;
  my $sd = $hub->species_defs;

  return '-' unless defined $value && $value ne '';

  $value =~ s/\,/\, /g;

  # location
  if($field eq 'Location') {
    my ($c, $s, $e) = split /\:|\-/, $value;
    $e ||= $s;
    $s -= 50;
    $e += 50;

    my $url = $hub->url({
      type             => 'Location',
      action           => 'View',
      r                => "$c:$s-$e",
      contigviewbottom => "variation_feature_variation=normal",
      species          => $species
    });

    $new_value = sprintf('<a class="_ht" title="View in location tab" href="%s">%s</a>', $url, $value);
  }

  # existing variation
  elsif($field eq 'Existing_variation' && $value =~ /\w+/) {

    foreach my $var(split /\,\s*/, $value) {

      my $url = $hub->url({
        type    => 'Variation',
        action  => 'Explore',
        v       => $var,
        species => $species
      });

      my $zmenu_url = $hub->url({
        type    => 'ZMenu',
        action  => 'Variation',
        v       => $var,
        species => $species
      });

      $new_value .= ($new_value ? ', ' : '').'<span>'.$self->zmenu_link($url, $zmenu_url, $var).'</span>';
    }
  }

  # transcript
  elsif($field eq 'Feature' && $value =~ /^ENS.{0,3}T\d+[\.\d+]*$/) {

    my $url = $hub->url({
      type    => 'Transcript',
      action  => 'Summary',
      t       => $value,
      species => $species,
      db      => $db_type,
    });

    my $zmenu_url = $hub->url({
      type    => 'ZMenu',
      action  => 'Transcript',
      t       => $value,
      species => $species,
      db      => $db_type,
    });

    $new_value = $self->zmenu_link($url, $zmenu_url, $value);
  }

  # reg feat
  elsif($field eq 'Feature' && $value =~ /^ENS.{0,3}R\d+$/) {

    my $url = $hub->url({
      type    => 'Regulation',
      action  => 'Summary',
      rf      => $value,
      species => $species
    });

    my $zmenu_url = $hub->url({
      type    => 'ZMenu',
      action  => 'Regulation',
      rf      => $value,
      species => $species
    });

    $new_value = $self->zmenu_link($url, $zmenu_url, $value);
  }

  # gene
  elsif($field eq 'Gene' && $value =~ /\w+/) {

    my $url = $hub->url({
      type    => 'Gene',
      action  => 'Summary',
      g       => $value,
      species => $species,
      db      => $db_type,
    });

    my $zmenu_url = $hub->url({
      type    => 'ZMenu',
      action  => 'Gene',
      g       => $value,
      species => $species,
      db      => $db_type,
    });

    $new_value = $self->zmenu_link($url, $zmenu_url, $value);
  }

  # Protein
  elsif($field eq 'ENSP' && $value =~ /\w+/) {
    my $url = $hub->url({
      type    => 'Transcript',
      action  => 'ProteinSummary',
      p       => $value,
      species => $species
    });

    $new_value = sprintf('<a href="%s">%s</a>', $url, $value);
  }

  # consequence type
  elsif($field eq 'Consequence' && $value =~ /\w+/) {
    my $cons = \%OVERLAP_CONSEQUENCES;
    my $var_styles   = $sd->colour('variation');
    my $colourmap    = $hub->colourmap;

    foreach my $con(split /\,\s+/, $value) {
      $new_value .= $new_value ? ', ' : '';

      if(defined($cons->{$con})) {
        my $colour = $var_styles->{lc $con} 
                     ? $colourmap->hex_by_name($var_styles->{lc $con}->{'default'})
                     : $colourmap->hex_by_name($var_styles->{'default'}->{'default'});

        $new_value .=
          sprintf(
            '<nobr><span class="colour" style="background-color:%s">&nbsp;</span> '.
            '<span class="_ht ht" title="%s">%s</span></nobr>',
            $colour, $cons->{$con}->description, $con
          );
      }
      else {
        $new_value .= $con;
      }
    }
  }

  # HGVS
  elsif($field =~ /^(hgvs|csn)/i && $value =~ /\w+/) {
    $new_value = uri_unescape($value);
  }

  # CCDS
  elsif($field eq 'CCDS' && $value =~ /\w+/) {
    $new_value = $hub->get_ExtURL_link($value, 'CCDS', $value)
  }
        
  # SIFT/PolyPhen
  elsif($field =~ /sift|polyphen/i && $value =~ /\w+/) {
    my ($pred, $score) = split /\(|\)/, $value;
    $pred =~ s/\_/ /g if $pred;

    # Missing score or prediction term
    if ($score !~ /^\d/) {
      $new_value = $pred;
    }
    # Having both prediction term and numerical score, or none of them (handled by 'render_sift_polyphen')
    else {
      $new_value = render_sift_polyphen($pred, $score);
    }
  }

  # codons
  elsif($field eq 'Codons' && $value =~ /\w+/) {
    $new_value = $value;
    $new_value =~ s/([A-Z]+)/<b>$1<\/b>/g;
    $new_value = uc($new_value);
  }

  # HGNC ID
  elsif($field eq 'HGNC_ID' && $value =~ /\w+/) {
    $new_value = $hub->get_ExtURL_link($value, 'HGNC', $value);
  }

  # UniProtKB/Swiss-Prot | UniProtKB/TrEMBL | UniParc
  elsif(($field eq 'SWISSPROT' || $field eq 'TREMBL' || $field eq 'UNIPROT_ISOFORM') && $value =~ /\w+/) {
    my $query = $value;
    $query =~ s/\.[\d]+$//g;
    $new_value = $hub->get_ExtURL_link($value, 'UNIPROT', $query);
  }

  # UniParc
  elsif(($field eq 'UNIPARC') && $value =~ /\w+/) {
    $new_value = $hub->get_ExtURL_link($value, 'UNIPARC', $value);
  }

  else {
    $new_value = defined($value) && $value ne '' ? $value : '-';
  }

  return $new_value;
}

# Get a list of comma separated items and transforms it into a bullet point list
sub get_items_in_list {
  my $self    = shift;
  my $row_id  = shift;
  my $type    = shift;
  my $label   = shift;
  my $data    = shift;
  my $species = shift;
  my $min_items_count = shift;
  my $extra   = shift;

  my $hub = $self->hub;

  $min_items_count ||= 5;

  my $div = ', ';
  if($type eq 'variant_synonyms'){
    $div = '--';
  }
  elsif($type eq 'IntAct_pmid' or $type eq 'IntAct_interaction_ac'){
    $div = ',';
  }

  my @items_list = split($div,$data);
  my @items_with_url;

  # Prettify format for phenotype entries
  if ($type eq 'phenotype') {
    @items_list = $self->prettify_phenotypes(\@items_list, $species);
    @items_with_url = @items_list;
  }
  elsif ($type eq 'disgenet') {
    foreach my $entry (@items_list) {
      # entry example '18630525:0.02:Malignant_Neoplasms'
      $entry =~ s/_/&nbsp;/g;
      my @disgenet_value = split /:/, $entry;
      my $pmid_url = $hub->get_ExtURL_link($disgenet_value[0], 'EPMC_MED', $disgenet_value[0]);
      my $new_entry = $pmid_url . ' <b>Score:</b>&nbsp;' . $disgenet_value[1] . ' <b>Disease:</b>&nbsp;' . $disgenet_value[2];
      push (@items_with_url, $new_entry);
    }
  }
  elsif ($type eq 'variant_synonyms') {
    my %synonyms;
    foreach my $entry (@items_list) {
      my @parts = split('::', $entry);
      $synonyms{$parts[0]} = $parts[1];
    }
    foreach my $source (keys %synonyms) {
      my @items_with_url_source;
      my $source_id = $source;
      if(uc $source eq 'CLINVAR') {
        $source_id = 'CLINVAR_VAR';
      }
      if(uc $source eq 'UNIPROT') {
        $source_id = 'UNIPROT_VARIATION';
      }
      if(uc $source eq 'PHARMGKB') {
        $source_id = 'PHARMGKB_VARIANT';
      }
      my @values = split(', ', $synonyms{$source});
      foreach my $value (@values) {
        my $new_value = $value;
        if(uc $source eq 'OMIM') {
          $new_value =~ s/\./#/;
        }
        next if(uc $source eq 'CLINVAR' && $value =~ /^RCV/);
        my $item_url = $hub->get_ExtURL_link($value, $source_id, $new_value);
        push(@items_with_url_source, uri_unescape($item_url));
      }
      $source =~ s/\_/ /g;
      my $new_source = '<b>'.$source.'</b>';
      push(@items_with_url, $new_source.'&nbsp;'.join(', ', @items_with_url_source));
    }
  }
  # Add external links
  else {
    foreach my $item (@items_list) {
      my $item_url = $item;
      if ($type eq 'pubmed') {
        $item_url = $hub->get_ExtURL_link($item, 'EPMC_MED', $item);
      }
      elsif ($item =~ /^(PDB-ENSP_mappings:)((.+)\.\w)$/i) {
        $item_url = "$1&nbsp;".$hub->get_ExtURL_link($2, 'PDB', $3);
      }
      elsif ($item =~ /^AFDB-ENSP_mappings:(.+)$/i) {
        # The format of an AlphaFold id is "AF-uniprot_id-fragment_number".
        # The AlphaFold site uses Uniprot ids as accession ids.
        my $alphafold_id = $1;
        my ( $uniprot_id ) = $alphafold_id =~ /-(.+)-/; # the middle part of an alphafold id

        $item_url = "AFDB-ENSP_mappings:" . "&nbsp" . $hub->get_ExtURL_link($alphafold_id, 'ALPHAFOLD', $uniprot_id);
      }
      elsif ($type eq 'mastermind_mmid3') {
        $item_url = $hub->get_ExtURL_link($item, 'MASTERMIND', $item);
      }
      elsif ($type eq 'IntAct_interaction_ac') {
      	$item =~ s/^\s+|\s+$//;
        $item_url = $hub->get_ExtURL_link($item, 'INTACT', $item);
      }
      elsif ($type eq 'IntAct_pmid') {
        $item =~ s/^\s+|\s+$//;
        $item_url = $hub->get_ExtURL_link($item, 'EPMC_MED', $item);
      }
      elsif ($type eq 'GO'){
        $item =~ s/^\s+|\s+$//;
        # Replace underscores with spaces to avoid long column width
        $item =~ s/_/ /g;

        # Some GO term descriptions have colons, so only split item by first 2 colons
        # e.g. GO:0008499:UDP-galactose:beta-N-acetylglucosamine_beta-1,3-galactosyltransferase_activity
        my @parts = split(":", $item, 3);
        my $go_term = "$parts[0]:$parts[1]";
        my $go_description = $parts[2];
        $item_url = $hub->get_ExtURL_link($go_term, 'GO', $go_term) . " $go_description";
      }
      elsif ($type eq 'MaveDB_urn') {
        $item_url = $hub->get_ExtURL_link($item, 'MAVEDB', $item);
      }
      elsif ($type eq 'PARALOGUE_REGIONS') {
        my ($chr, $start, $end, $transcript_id, $perc_cov, $perc_pos) = split /:/, $item;

        my $db_adaptor  = $self->hub->database('core');
        my $adaptor     = $db_adaptor->get_TranscriptAdaptor;
        my $transcript  = $adaptor->fetch_by_stable_id($transcript_id);
        my $hom_gene    = $transcript->get_Gene->stable_id;

        my $gene = $extra->{'gene_id'};
        my $aln_url = "/Homo_sapiens/Gene/Compara_Paralog/Alignment?g=${gene};g1=${hom_gene}";

        # show transcript zmenu when clicking on transcript ID
        my $transcript_url = $hub->url({
          type    => 'Transcript',
          action  => 'Summary',
          t       => $transcript_id,
          species => $species,
          db      => 'core',
        });
        my $transcript_zmenu_url = $hub->url({
          type    => 'ZMenu',
          action  => 'Transcript',
          t       => $transcript_id,
          species => $species,
          db      => 'core',
        });
        my $transcript_zmenu = $self->zmenu_link($transcript_url, $transcript_zmenu_url, $transcript_id);

        my $location = $end eq $start ? "$chr:$start" : "$chr:$start-$end";
        $item_url = sprintf "<b>$location</b> (". $transcript_zmenu .", coverage: %0.f%%, positivity: %0.f%%)", $perc_cov, $perc_pos;
        $item_url .= "<div class='in-table-button' style='line-height: 20px'><a href='${aln_url}' rel='external' class='constant'>Paralogue alignment</a></div>";

        # list paralogue variants if within this region
        my $paralogue_variants = $extra->{'paralogue_variants'};
        my $vars_html;
        for my $var (@$paralogue_variants) {
          if ($var->{chr} eq $chr && $var->{start} >= $start && $var->{start} <= $end) {
            $vars_html .= "<li>$var->{item_url}</li>";
          }
        }
        $item_url .= "<ul>$vars_html</ul>" if defined $vars_html;
      }
      elsif ($type eq 'Geno2MP_HPO_count') {
        $item_url = '<a href="' . $extra . '" rel="external" class="constant">' . $item_url . '</a>';
      }
      elsif ($type eq 'domains') {
        my ($domain_label, $value) = split(":", $item, 2);
        my $key = $PROTEIN_DOMAIN_LABELS{$domain_label};
        my $value_url = $value;
        $value_url = "G3DSA:$value" if $domain_label eq "Gene3D" and $value !~ /^G3DSA:/;
        $item_url = "$domain_label:&nbsp;" . $hub->get_ExtURL_link($value, $key, $value_url);
      }
      push(@items_with_url, $item_url);
    }
  }

  if (scalar @items_list > $min_items_count) {
    my $div_id = 'row_'.$row_id.'_'.$type;
    return display_items_list($div_id, $type, $label, \@items_with_url, \@items_list);
  }
  else {
    return join('<br />',@items_with_url);
  }
}

sub render_protein_matches {
  my (
    $self,
    $row_data,
    $row_id,
    $gene_id,
    $feature_id,
    $consequence,
    $species
  ) = @_;

  my $hub = $self->hub;
  my $domain_ids = $row_data->{'DOMAINS'};

  my $should_add_pdb_view_button = $domain_ids =~ /PDB-ENSP/i;
  # we are currently only comfortable with showing the alphafold view only in case of missense variants
  my $should_add_afdb_view_button = $domain_ids =~ /AFDB-ENSP/i && $consequence =~ /missense_variant/i;
  my $should_add_protein_view_buttons = $should_add_pdb_view_button || $should_add_afdb_view_button;

  my $rendered_protein_matches = $self->get_items_in_list($row_id, 'domains', 'Protein matches', $domain_ids, $species);

  if (!$should_add_protein_view_buttons) {
    $row_data->{'DOMAINS'} = $rendered_protein_matches;
    return;
  }

  my $db_adaptor  = $hub->database('core');
  my $adaptor     = $db_adaptor->get_TranscriptAdaptor;
  my $transcript  = $adaptor->fetch_by_stable_id($feature_id);
  my $safe_transcript_id = $transcript ? $transcript->stable_id : $feature_id;

  my $pdb_structure_button = '';
  my $afdb_structure_button = '';

  if ($should_add_pdb_view_button) {
    my $url = $hub->url({
      type    => 'Tools',
      action  => 'VEP/PDB',
      var     => $row_data->{'ID'},
      pos     => $row_data->{'Protein_position'},
      cons    => $consequence,
      g       => $gene_id,
      t       => $safe_transcript_id,
      species => $species
    });

    $pdb_structure_button = qq{<div class="in-table-button"><a href="$url">Protein Structure View</a></div>};
  }

  if ($should_add_afdb_view_button) {
    my $url = $hub->url({
      type    => 'Tools',
      action  => 'VEP/AFDB',
      var     => $row_data->{'ID'},
      pos     => $row_data->{'Protein_position'},
      cons    => $consequence,
      g       => $gene_id,
      t       => $safe_transcript_id,
      species => $species
    });

    $afdb_structure_button = qq{<div class="in-table-button"><a href="$url">Alphafold model</a></div>};
  }

  $row_data->{'DOMAINS'} = $pdb_structure_button . $afdb_structure_button . $rendered_protein_matches;
}

sub reload_link {
  my ($self, $html, $url_params) = @_;

  return sprintf('<a href="%s" class="_reload"><input type="hidden" value="%s" />%s</a>',
    $self->hub->url({%$url_params, 'update_panel' => undef}, undef, 1),
    $self->ajax_url(undef, {%$url_params, 'update_panel' => 1}, undef, 1),
    $html
  );
}

sub zmenu_link {
  my ($self, $url, $zmenu_url, $html) = @_;

  return sprintf('<a class="_zmenu" href="%s">%s</a><a class="hidden _zmenu_link" href="%s"></a>', $url, $html, $zmenu_url);
}

1;
