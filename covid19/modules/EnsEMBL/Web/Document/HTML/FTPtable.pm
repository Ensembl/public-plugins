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

package EnsEMBL::Web::Document::HTML::FTPtable;

### This module outputs a table of links to the FTP site

use strict;

sub render {
  my $self            = shift;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;

  my $html;

  my $ftp = $species_defs->ENSEMBL_GENOMES_FTP_URL;

  (my $ftp_domain = $ftp) =~ s/\/pub//;

  $html .= qq(<p>
Each directory on <a href="$ftp" rel="external">$ftp_domain</a> contains a
<a href="$ftp/current_README">README</a> file, explaining the directory structure.
</p>
  );

  my ($columns, $rows);
  
  my %title = (
    dna       => 'Masked and unmasked genome sequences associated with the assembly (contigs, chromosomes etc.)',
    cdna      => 'cDNA sequences for both Ensembl and "ab initio" predicted genes',
    cds       => 'Coding sequences for Ensembl or "ab initio" predicted genes',
    prot      => 'Protein sequences for Ensembl or "ab initio" predicted genes',
    embl      => 'Ensembl database dumps in EMBL nucleotide sequence database format',
    genbank   => 'Ensembl database dumps in GenBank nucleotide sequence database format',
    tsv       => 'External references in TSV format',
    json      => 'External references and other annotation data in JSON format',
    gtf       => 'Gene sets for each species. These files include annotations of both coding and non-coding genes',
    gff3      => 'GFF3 provides access to all annotated transcripts which make up an Ensembl gene set',
    vep       => 'Cache files for use with the Ensembl VEP script',
  );

  $title{$_} = encode_entities($title{$_}) for keys %title;
  
  $columns = [
    { key => 'species', title => 'Species',                      align => 'left',   width => '10%', sort => 'html' },
    { key => 'dna',     title => 'DNA (FASTA)',                  align => 'center', width => '10%', sort => 'none' },
    { key => 'cdna',    title => 'cDNA (FASTA)',                 align => 'center', width => '10%', sort => 'none' },
    { key => 'cds',     title => 'CDS (FASTA)',                  align => 'center', width => '10%', sort => 'none' },
    { key => 'protseq', title => 'Protein sequence (FASTA)',     align => 'center', width => '10%', sort => 'none' },
    { key => 'embl',    title => 'Annotated sequence (EMBL)',    align => 'center', width => '10%', sort => 'none' },
    { key => 'genbank', title => 'Annotated sequence (GenBank)', align => 'center', width => '10%', sort => 'none' },
    { key => 'genes',   title => 'Gene sets',                    align => 'center', width => '10%', sort => 'none' },
    { key => 'xrefs',   title => 'Other annotations',            align => 'center', width => '10%', sort => 'none' },
    { key => 'var',     title => 'Variation (Ensembl VEP)',      align => 'center', width => '10%', sort => 'html' }
  ];

  my $all_species = [{
                      'url'       => $species_defs->SPECIES_URL, 
                      'name'      => $species_defs->SPECIES_DISPLAY_NAME,
                      'dir'       => $species_defs->SPECIES_PRODUCTION_NAME,
                      'species'   => $species_defs->get_species_name($hub->species),
                      'strain'    => $species_defs->SPECIES_STRAIN
                      }];

  my $ftp_base = $ftp.'/viruses';

  foreach my $sp (@$all_species) {
    my $sp_url  = $sp->{'url'};
    my $sp_dir    = $sp->{'dir'};
    my $sp_name    = $sp->{'name'};
    my $sp_link = sprintf('<b><a href="/%s/">%s</a></b>', $sp_url, $sp_name);
    my $sp_var    = $sp_name. '_variation';
    
    push @$rows, {
      species => $sp_link, 
      dna     => sprintf('<a rel="external" title="%s" href="%s/fasta/%s/dna/">FASTA</a>', $title{'dna'},  $ftp_base, $sp_dir),
      cdna    => sprintf('<a rel="external" title="%s" href="%s/fasta/%s/cdna/">FASTA</a>',  $title{'cdna'}, $ftp_base, $sp_dir),
      cds	    => sprintf('<a rel="external" title="%s" href="%s/fasta/%s/cds/">FASTA</a>',   $title{'cds'}, $ftp_base, $sp_dir),
      protseq => sprintf('<a rel="external" title="%s" href="%s/fasta/%s/pep/">FASTA</a>',   $title{'prot'}, $ftp_base, $sp_dir),
      embl    => sprintf('<a rel="external" title="%s" href="%s/embl/%s/">EMBL</a>',         $title{'embl'},  $ftp_base, $sp_dir),
      genbank => sprintf('<a rel="external" title="%s" href="%s/genbank/%s/">GenBank</a>',   $title{'genbank'}, $ftp_base, $sp_dir),
      genes   => sprintf('<a rel="external" title="%s" href="%s/gtf/%s">GTF</a> <a rel="external" title="%s" href="%s/gff3/%s">GFF3</a>', $title{'gtf'}, $ftp_base, $sp_dir, $title{'gff3'}, $ftp_base, $sp_dir),
      xrefs   => sprintf('<a rel="external" title="%s" href="%s/tsv/%s">TSV</a> <a rel="external" title="%s" href="%s/json/%s">JSON</a>', $title{'tsv'}, $ftp_base, $sp_dir, $title{'json'}, $ftp_base, $sp_dir),
      var    => sprintf('<a rel="external" title="%s" href="%s/variation/vep/">Ensembl VEP</a>',    $title{'vep'}, $ftp_base),
    };

  }

  my $main_table           = EnsEMBL::Web::Document::Table->new($columns, $rows, { data_table => 1, exportable => 0 });
  $main_table->code        = 'FTPtable::'.scalar(@$rows);
  $main_table->{'options'}{'data_table_config'} = {iDisplayLength => 10};
 

  $html .= sprintf(qq{
    <div class="js_panel" id="ftp-table">
      <input type="hidden" class="panel_type" value="Content">
      %s
    </div>
    %s
  }, $main_table->render, $self->add_footnotes);

  return $html;
}

sub add_footnotes {
  my $self = shift;
  my $hub = $self->hub;
  my $sd = $hub->species_defs;

  my $html = qq(
    <p>
To facilitate storage and download all databases are
<a href="http://directory.fsf.org/project/gzip/" rel="external">GNU
Zip</a> (gzip, *.gz) compressed.
</p>

<h2>About the data</h2>

<p>
The following types of data dumps are available on the FTP site.
</p>

<dl class="twocol striped">
<dt class="bg2">FASTA</dt>
<dd class="bg2">FASTA sequence databases of Ensembl gene, transcript and protein
model predictions. Since the
<a href="http://www.bioperl.org/wiki/FASTA_sequence_format"
rel="external">FASTA format</a> does not permit sequence annotation,
these database files are mainly intended for use with local sequence
similarity search algorithms. Each directory has a README file with a
detailed description of the header line format and the file naming
conventions.
<dl>
  <dt>DNA</dt>
  <dd><a href="http://www.repeatmasker.org/" rel="external">Masked</a>
  and unmasked genome sequences associated with the assembly (contigs,
  chromosomes etc.).</dd>
  <dd>The header line in an FASTA dump files containing DNA sequence
  consists of the following attributes :
  coord_system:version:name:start:end:strand
  This coordinate-system string is used in the Ensembl API to retrieve
  slices with the SliceAdaptor.</dd>

  <dt>CDS</dt>
  <dd>Coding sequences for Ensembl or <i>ab
  initio</i> <a href="https://www.ensembl.org/info/genome/genebuild/">predicted
  genes</a>.</dd>

  <dt>cDNA</dt>
  <dd>cDNA sequences for Ensembl or <i>ab
  initio</i> <a href="https://www.ensembl.org/info/genome/genebuild/">predicted
  genes</a>.</dd>

  <dt>Peptides</dt>
  <dd>Protein sequences for Ensembl or <i>ab
  initio</i> <a href="https://www.ensembl.org/info/genome/genebuild/">predicted
  genes</a>.</dd>

</dl>

</dd>

<dt class="bg1">Annotated sequence</dt>
<dd class="bg1">Flat files allow more extensive sequence annotation by means of
feature tables and contain thus the genome sequence as annotated by
the automated Ensembl
<a href="https://www.ensembl.org/info/genome/genebuild/">genome
annotation pipeline</a>. Each nucleotide sequence record in a flat
file represents a 1Mb slice of the genome sequence. Flat files are
broken into chunks of 1000 sequence records for easier downloading.
  <dl>

  <dt>EMBL</dt>
  <dd>Ensembl database dumps in <a href="http://www.ebi.ac.uk/ena/about/sequence_format"
  rel="external">EMBL</a> nucleotide
  sequence <a href="https://ftp.ebi.ac.uk/pub/databases/embl/doc/usrman.txt"
  rel="external">database format</a></dd>

  <dt>GenBank</dt>
  <dd>Ensembl database dumps
  in <a href="http://www.ncbi.nlm.nih.gov/genbank/"
  rel="external">GenBank</a> nucleotide sequence
  <a href="http://www.ncbi.nlm.nih.gov/Sitemap/samplerecord.html"
  rel="external">database format</a></dd>

  </dl>

</dd>

<dt class="bg2">GTF</dt>
<dd class="bg2">Gene sets for each species. These files include annotations of
both coding and non-coding genes. This file format is
described <a href="http://www.gencodegenes.org/pages/data_format.html">here</a>.
</dd>

<dt class="bg1">GFF3</dt>
<dd class="bg1">GFF3 provides access to all annotated transcripts which make
up an Ensembl gene set. This file format is
described <a href="http://www.sequenceontology.org/gff3.shtml">here</a>.
</dd>
 
<dt class="bg2">VEP (variation data)</dt>
<dd class="bg2">Compressed text files (called "cache files") used by the <a href="/VEP">Variant Effect Predictor</a> tool. More information about these files is available <a href="https://www.ensembl.org/info/docs/tools/vep/script/vep_cache.html">here</a>.</dd>

</dl>
);

  return $html;
}

1;
