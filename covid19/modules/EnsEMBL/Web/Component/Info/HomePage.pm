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

package EnsEMBL::Web::Component::Info::HomePage;

use strict;

sub assembly_text {
  my $self              = shift;
  my $hub               = $self->hub;
  my $species_defs      = $hub->species_defs;
  my $species           = $hub->species;
  my $species_prod_name = $species_defs->get_config($species, 'SPECIES_PRODUCTION_NAME');
  my $sample_data       = $species_defs->SAMPLE_DATA;
  my $ftp               = $species eq 'Sars_cov_2' ? $self->ftp_url : '';
  my $assembly          = $species_defs->ASSEMBLY_NAME;
  my $assembly_version  = $species_defs->ASSEMBLY_VERSION;
  my $mappings          = $species_defs->ASSEMBLY_MAPPINGS;
  my $gca               = $species_defs->ASSEMBLY_ACCESSION;

  my $html = sprintf('
    <div class="homepage-icon">
      %s
    </div>
    <h2>Genome assembly: %s%s</h2>
    %s
    <p><a href="%s" class="nodeco">%sMore information and statistics</a></p>
    %s
    <p><a href="%s" class="modal_link nodeco" rel="modal_user_data">%sDisplay your data in %s</a></p>',

  sprintf(
      $self->{'img_link'},
      $hub->url({ type => 'Location', action => 'View', r => $sample_data->{'LOCATION_PARAM'}, __clear => 1 }),
      "Go to $sample_data->{'LOCATION_TEXT'}", 'region', 'Example region'
    ),

    $assembly, $gca ? " <small>($gca)</small>" : '',

    $hub->species eq 'Sars_cov_2' ? '' : sprintf('<p>The %s genome was imported from <a href="https://www.ebi.ac.uk/ena/browser/view/%s">ENA</a> to conduct comparative analysis with SARS-CoV-2.</p>', $hub->species_defs->SPECIES_DISPLAY_NAME, $gca),

    $hub->url({ action => 'Annotation', __clear => 1 }), sprintf($self->{'icon'}, 'info'),

    $ftp ? sprintf(
      '<p><a href="%s/fasta/%s/dna/" class="nodeco">%sDownload DNA sequence</a> (FASTA)</p>', ## Link to FTP site
      $ftp, $species_prod_name, sprintf($self->{'icon'}, 'download')
    ) : '',

    $hub->url({ type => 'UserData', action => 'SelectFile', __clear => 1 }), sprintf($self->{'icon'}, 'page-user'), $species_defs->ENSEMBL_SITETYPE
  );

  return $html;
}


sub genebuild_text {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $hub->species;
  my $sp_prod_name = $species_defs->get_config($species, 'SPECIES_PRODUCTION_NAME');
  my $sample_data  = $species_defs->SAMPLE_DATA;
  my $ftp          = $species eq 'Sars_cov_2' ? $self->ftp_url : '';
  my $vega         = $species_defs->SUBTYPE !~ /Archive|Pre/ && $species_defs->get_config('MULTI', 'ENSEMBL_VEGA') || {};
  my $idm_link     = $species_defs->ENSEMBL_IDM_ENABLED
    ? sprintf('<p><a href="%s" class="nodeco">%sUpdate your old Ensembl IDs</a></p>', $hub->url({ type => 'Tools', action => 'IDMapper', __clear => 1 }), sprintf($self->{'icon'}, 'tool'))
    : '';

  return sprintf('
    <div class="homepage-icon">
      %s
      %s
    </div>
    <h2>Gene annotation</h2>
    <p><strong>What can I find?</strong> Protein-coding and non-coding genes, splice variants, cDNA and protein sequences, non-coding RNAs.</p>
    <p><a href="%s" class="nodeco">%sMore about this genebuild</a></p>
    %s
    %s
    %s',
    
    sprintf(
      $self->{'img_link'},
      $hub->url({ type => 'Gene', action => 'Summary', g => $sample_data->{'GENE_PARAM'}, __clear => 1 }),
      "Go to gene $sample_data->{'GENE_TEXT'}", 'gene', 'Example gene'
    ),
    
    sprintf(
      $self->{'img_link'},
      $hub->url({ type => 'Transcript', action => 'Summary', t => $sample_data->{'TRANSCRIPT_PARAM'} }),
      "Go to transcript $sample_data->{'TRANSCRIPT_TEXT'}", 'transcript', 'Example transcript'
    ),
    
    $hub->url({ action => 'Annotation', __clear => 1 }), sprintf($self->{'icon'}, 'info'),
    
    $ftp ? sprintf(
      '<p><a href="%s/fasta/%s/" class="nodeco">%sDownload FASTA</a> files</p>', ## Link to FTP site
      $ftp, $sp_prod_name, sprintf($self->{'icon'}, 'download')
    ) : '',
    
    $ftp ? sprintf(
      '<p><a href="%s/gtf/%s/" class="nodeco">%sDownload GTF</a> or <a href="%s/gff3/%s/" class="nodeco">GFF3</a> files</p>', ## Link to FTP site
      $ftp, $sp_prod_name, sprintf($self->{'icon'}, 'download'), $ftp, $sp_prod_name
    ) : '',
    
    $idm_link
  );
}

sub compara_text {
  my $self         = shift;

  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $sample_data  = $species_defs->SAMPLE_DATA;
  my $ftp          = $hub->species eq 'Sars_cov_2' ? $self->ftp_url : '';

  return sprintf('
    <div class="homepage-icon">
      %s
    </div>
    <h2>Comparative genomics</h2>
    <p><strong>What can I find?</strong>  Homologues, gene trees, and whole genome alignments across multiple species.</p>
    <p><a href="/info/genome/" class="nodeco">%sMore about comparative analysis</a></p>',

    sprintf(
      $self->{'img_link'},
      $hub->url({ type => 'Gene', action => 'Compara_Tree', g => $sample_data->{'GENE_PARAM'}, __clear => 1 }),
      "Go to gene tree for $sample_data->{'GENE_TEXT'}", 'compara', 'Example gene tree'
    ),
   
    sprintf($self->{'icon'}, 'info'),

  );
}

sub variation_text {
  my $self              = shift;
  my $hub               = $self->hub;
  my $species_defs      = $hub->species_defs;
  my $species_prod_name = $species_defs->get_config($hub->species, 'SPECIES_PRODUCTION_NAME');
  my $html;

  if ($hub->database('variation') && $hub->species eq 'Sars_cov_2') {
    my $sample_data  = $species_defs->SAMPLE_DATA;
    my $ftp          = $self->ftp_url;

    ## Split variation param if required (e.g. vervet monkey)
    my ($v, $vf) = split(';vf=', $sample_data->{'VARIATION_PARAM'});
    my %v_params = ('v' => $v);
    $v_params{'vf'} = $vf if $vf;

    $html = sprintf('
      <div class="homepage-icon">
        %s
      </div>
      <h2>Variation</h2>
      <p><strong>What can I find?</strong> Short sequence variants</p>
      <p><a href="%s" class="nodeco">%sMore about this variation data</a></p>
      %s',
      
      $v ? sprintf(
        $self->{'img_link'},
        $hub->url({ type => 'Variation', action => 'Explore', __clear => 1, %v_params }),
        "Go to variant $sample_data->{'VARIATION_TEXT'}", 'variation', 'Example variant'
      ) : '',
      
      $hub->url({ action => 'Variation', __clear => 1 }),
      sprintf($self->{'icon'}, 'info'),
      
    );

    if ($species_defs->ENSEMBL_VEP_ENABLED) {
      $html .= sprintf(
        qq(<p><a href="%s" class="nodeco">$self->{'icon'}Variant Effect Predictor<img src="%svep_logo_sm.png" style="vertical-align:top;margin-left:12px" /></a></p>),
        $hub->url({'__clear' => 1, qw(type Tools action VEP)}),
        'tool',
        $self->img_url
      );
    }
  }
  else {
    $html = '';
  }

  return $html;
}

1;

