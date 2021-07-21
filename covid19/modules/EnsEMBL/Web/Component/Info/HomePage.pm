=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

sub genebuild_text {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $hub->species;
  my $sp_prod_name = $species_defs->get_config($species, 'SPECIES_PRODUCTION_NAME');
  my $sample_data  = $species_defs->SAMPLE_DATA;
  my $ftp          = $self->ftp_url;
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

sub variation_text {
  my $self              = shift;
  my $hub               = $self->hub;
  my $species_defs      = $hub->species_defs;
  my $species_prod_name = $species_defs->get_config($hub->species, 'SPECIES_PRODUCTION_NAME');
  my $html;

  if($species_defs->NO_VARIATION && !$species_defs->ENSEMBL_VEP_ENABLED){
    return '';
  }
  
  if ($hub->database('variation')) {
    my $sample_data  = $species_defs->SAMPLE_DATA;

    ## Split variation param if required (e.g. vervet monkey)
    my ($v, $vf) = split(';vf=', $sample_data->{'VARIATION_PARAM'});
    my %v_params = ('v' => $v);
    $v_params{'vf'} = $vf if $vf;

    my $ftp          = $self->ftp_url;
       $html         = sprintf('
      <div class="homepage-icon">
        %s
        %s
        %s
      </div>
      <h2>Variation</h2>
      <p><strong>What can I find?</strong> Short sequence variants%s%s</p>
      <p><a href="%s" class="nodeco">%sMore about this variation data</a></p>
      %s',
      
      $v ? sprintf(
        $self->{'img_link'},
        $hub->url({ type => 'Variation', action => 'Explore', __clear => 1, %v_params }),
        "Go to variant $sample_data->{'VARIATION_TEXT'}", 'variation', 'Example variant'
      ) : '',
      
      $sample_data->{'PHENOTYPE_PARAM'} ? sprintf(
        $self->{'img_link'},
        $hub->url({ type => 'Phenotype', action => 'Locations', ph => $sample_data->{'PHENOTYPE_PARAM'}, __clear => 1 }),
        "Go to phenotype $sample_data->{'PHENOTYPE_TEXT'}", 'phenotype', 'Example phenotype'
      ) : '',
      
      $sample_data->{'STRUCTURAL_PARAM'} ? sprintf(
        $self->{'img_link'},
        $hub->url({ type => 'StructuralVariation', action => 'Explore', sv => $sample_data->{'STRUCTURAL_PARAM'}, __clear => 1 }),
        "Go to structural variant $sample_data->{'STRUCTURAL_TEXT'}", 'struct_var', 'Example structural variant'
      ) : '',
      
      $species_defs->databases->{'DATABASE_VARIATION'}{'STRUCTURAL_VARIANT_COUNT'} ? ' and longer structural variants' : '', $sample_data->{'PHENOTYPE_PARAM'} ? '; disease and other phenotypes' : '',

      $hub->url({ action => 'Annotation', __clear => 1 }),
      sprintf($self->{'icon'}, 'info'),
      
      $ftp ? sprintf(
        '<p><a href="%s/variation/gvf/%s/" class="nodeco" style="pointer-events: none; color: grey">%sDownload all variants</a> (GVF)</p>', ## Link to FTP site
        $ftp, $species_prod_name, sprintf($self->{'icon'}, 'download')
      ) : ''
    );
  } else {
    $html .= '
      <h2>Variation</h2>
      <p>This species currently has no variation database. However you can process your own variants using the Variant Effect Predictor:</p>
    ';
  }

  if ($species_defs->ENSEMBL_VEP_ENABLED) {
    $html .= sprintf(
      qq(<p><a href="%s" class="nodeco">$self->{'icon'}Variant Effect Predictor<img src="%svep_logo_sm.png" style="vertical-align:top;margin-left:12px" /></a></p>),
      $hub->url({'__clear' => 1, qw(type Tools action VEP)}),
      'tool',
      $self->img_url
    );
  }

  return $html;
}

1;

