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

package EnsEMBL::Web::Component::Info::SpeciesBlurb;

use strict;

sub page_header {
  my $self      = shift;
  my $hub       = $self->hub;
  my $sci_name  = $hub->species_defs->SPECIES_SCIENTIFIC_NAME;

  my $html = sprintf '<div class="round-box tinted-box unbordered"><h2>Search <i>%s</i></h2>%s</div>',
                        $sci_name, EnsEMBL::Web::Document::HTML::HomeSearch->new($hub)->render;

  return $html;
}

sub column_left {
  my $self      = shift;
  my $species   = $self->hub->species;

  my $html = '<div class="column-padding no-left-margin">';

  my $img_url      = $self->img_url;
  $self->{'icon'}  = qq(<img src="${img_url}24/%s.png" alt="" class="homepage-link" />);
  $self->{'img_link'} = qq(<a class="nodeco _ht _ht_track" href="%s" title="%s"><img src="${img_url}96/%s.png" alt="" class="bordered" />%s</a>);

  $html .= sprintf('
    <div class="round-box tinted-box unbordered">%s</div>
    <div class="round-box tinted-box unbordered">%s</div>',
    $self->assembly_text,
    $self->genebuild_text);

  $html .= '</div>';

  return $html;
}

sub assembly_text {
  my $self      = shift;
  my $hub               = $self->hub;
  my $species_defs      = $hub->species_defs;
  my $species           = $hub->species;
  my $species_prod_name = $species_defs->get_config($species, 'SPECIES_PRODUCTION_NAME');
  my $sample_data       = $species_defs->SAMPLE_DATA;
  my $ftp               = $species_defs->ENSEMBL_FTP_URL;
  my $assembly          = $species_defs->ASSEMBLY_NAME;
  my $assembly_version  = $species_defs->ASSEMBLY_VERSION;
  my $gca               = $species_defs->ASSEMBLY_ACCESSION;

  my $karyotype = '';
  if (scalar @{$species_defs->ENSEMBL_CHROMOSOMES || []} && !$species_defs->NO_KARYOTYPE) {
    $karyotype = sprintf($self->{'img_link'},
                  $hub->url({ type => 'Location', action => 'Genome', __clear => 1 }),
                  'Go to ' . $species_defs->SPECIES_SCIENTIFIC_NAME . ' karyotype',
                  'karyotype', 'View karyotype'
                  );
  }

  my $html = sprintf('
    <div class="homepage-icon">
      %s
      %s
    </div>
    <h2>Genome assembly: %s%s</h2>
    %s
    <p><a href="%s" class="modal_link nodeco" rel="modal_user_data">%sDisplay your data in %s</a></p>',

    $karyotype,

    sprintf(
      $self->{'img_link'},
      $hub->url({ type => 'Location', action => 'View', r => $sample_data->{'LOCATION_PARAM'}, __clear => 1 }),
      "Go to $sample_data->{'LOCATION_TEXT'}", 'region', 'Example region'
    ),

    $assembly, 
    $gca ? " <small>($gca)</small>" : '',

    $ftp ? sprintf(
      '<p><a href="%s" class="nodeco">%sDownload DNA sequence</a> (FASTA)</p>', ## Link to FTP site
      $self->format_ftp_url('dna'), sprintf($self->{'icon'}, 'download')
    ) : '',

    $hub->url({ type => 'UserData', action => 'SelectFile', __clear => 1 }), 

    sprintf($self->{'icon'}, 'page-user'), 
    $species_defs->ENSEMBL_SITETYPE
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
  my $ftp          = $species_defs->ENSEMBL_FTP_URL;
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

    $ftp ? sprintf(
      '<p><a href="%s" class="nodeco">%sDownload FASTA, GTF or GFF3</a> files for genes, cDNAs, ncRNA, proteins</p>', ## Link to FTP site
      $self->format_ftp_url, sprintf($self->{'icon'}, 'download')
    ) : '',

    $idm_link
  );
}

sub format_ftp_url {
  my ($self, $link_type) = @_;
  my $sd  = $self->hub->species_defs;

  my $species = ucfirst($sd->STRAIN_GROUP || $sd->SPECIES_DB_NAME || $sd->SPECIES_PRODUCTION_NAME);
  ## Remove any assembly accession from chosen name
  $species =~ s/_gca\d+//;
  $species =~ s/v\d+$//;
  my $url = sprintf '%s/species/%s/%s', $sd->ENSEMBL_FTP_URL, $species, $sd->ASSEMBLY_ACCESSION;

  if ($link_type eq 'dna') {
    $url .= '/genome/';
  }
  else {
    my $geneset = $sd->LAST_GENESET_UPDATE;
    $geneset    =~ s/-/_/g;
    $url       .= sprintf '/geneset/%s/', $geneset;
  }

  return $url;
}

1;
