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

package EnsEMBL::Web::Document::HTML::FTPtable;

### This module outputs a table of links to the FTP site

use strict;

use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::Document::Table;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $self            = shift;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;

  my $html;

  my $ftp = $species_defs->ENSEMBL_FTP_URL;
  (my $ftp_domain = $ftp) =~ s/\/pub//;
 
  $html .= qq(<p>
Each directory on <a href="$ftp" rel="external">$ftp_domain</a> contains a
<a href="$ftp/current_README">README</a> file, explaining the directory structure.
</p>
  );

  my $required_lookup = $self->required_types_for_species;
  my ($columns, $rows);
  
  my %title = (
    dna       => 'Masked and unmasked genome sequences associated with the assembly (contigs, chromosomes etc.)',
    cdna      => 'cDNA sequences for both Ensembl and "ab initio" predicted genes',
    cds       => 'Coding sequences for Ensembl or "ab initio" predicted genes',
    prot      => 'Protein sequences for Ensembl or "ab initio" predicted genes',
    rna       => 'Non-coding RNA gene predictions',
    embl      => 'Ensembl database dumps in EMBL nucleotide sequence database format',
    genbank   => 'Ensembl database dumps in GenBank nucleotide sequence database format',
    tsv       => 'External references in TSV format',
    rdf       => 'External references and other annotation data in RDF format',
    json      => 'External references and other annotation data in JSON format',
    gtf       => 'Gene sets for each species. These files include annotations of both coding and non-coding genes',
    gff3      => 'GFF3 provides access to all annotated transcripts which make up an Ensembl gene set',
    mysql     => 'All Ensembl MySQL databases are available in text format as are the SQL table definition files',
    emf       => 'Alignments of resequencing data from the ensembl_compara database',
    gvf       => 'Variation data in GVF format',
    vcf       => 'Variation data in VCF format',
    vep       => 'Cache files for use with the VEP script',
    coll      => 'Additional regulation data (not in the database)',
    bed       => 'Constrained elements calculated using GERP',
    ancestral => 'Ancestral Allele data in FASTA format',
  );

  $title{$_} = encode_entities($title{$_}) for keys %title;
  
  $columns = [
    { key => 'species', title => 'Species',         align => 'left',   width => '50%', sort => 'html' },
    { key => 'dna',     title => 'DNA',             align => 'center', width => '20%', sort => 'none' },
    { key => 'genes',   title => 'Gene sets',       align => 'center', width => '20%', sort => 'none' },
    { key => 'rnaseq',  title => 'RNA Seq',         align => 'center', width => '10%', sort => 'none' },
  ];

  my $all_species = [];
  foreach ($species_defs->valid_species) {
    my $species = ucfirst($species_defs->get_config($_, 'STRAIN_GROUP') 
                        || $species_defs->get_config($_, 'SPECIES_DB_NAME')
                        || $species_defs->get_config($_, 'SPECIES_PRODUCTION_NAME'));
    ## Remove any assembly accession from chosen name
    $species =~ s/_gca\d+//;
    $species =~ s/v\d+$//;
    push @$all_species, {
                          'species'   => $species,
                          'url'       => $species_defs->get_config($_, 'SPECIES_URL'), 
                          'name'      => $species_defs->get_config($_, 'SPECIES_DISPLAY_NAME'),
                          'assembly'  => $species_defs->get_config($_, 'ASSEMBLY_ACCESSION'),
                        }
  }

  foreach my $sp (sort {$a->{'name'} cmp $b->{'name'}} @$all_species) {
    my $sp_url  = $sp->{'url'};
    my $name    = $sp->{'name'};
    my $sp_link = sprintf('<b><a href="/%s/">%s</a></b>', $sp_url, $name);

    my $sub_dir   = sprintf 'species/%s/%s', $sp->{'species'}, $sp->{'assembly'};
    my $databases = $species_defs->get_config($sp_url, 'databases');
    my $geneset   = $species_defs->get_config($sp_url, 'LAST_GENESET_UPDATE');
    $geneset      =~ s/-/_/g;
    
    push @$rows, {
      species => $sp_link, 
      dna     => sprintf('<a rel="external" title="%s" href="%s/%s/genome/">FASTA</a>', $title{'dna'},  $ftp, $sub_dir),
      genes   => sprintf('<a rel="external" title="%s" href="%s/%s/geneset/%s/">FASTA/GTF/GFF3/TSV</a>', $title{'genes'}, $ftp, $sub_dir, $geneset),
      rnaseq   => $databases->{'DATABASE_RNASEQ'} ? sprintf('<a rel="external" title="%s" href="%s/%s/rnaseq/">BAM</a>', $title{'rna'}, $ftp, $sub_dir) : '-',
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


  <dt>RNA</dt>
  <dd>Non-coding RNA gene predictions.</dd>

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
  sequence <a href="ftp://ftp.ebi.ac.uk/pub/databases/embl/doc/usrman.txt"
  rel="external">database format</a></dd>

  <dt>GenBank</dt>
  <dd>Ensembl database dumps
  in <a href="http://www.ncbi.nlm.nih.gov/genbank/"
  rel="external">GenBank</a> nucleotide sequence
  <a href="http://www.ncbi.nlm.nih.gov/Sitemap/samplerecord.html"
  rel="external">database format</a></dd>

  </dl>

</dd>

<dt class="bg1">GTF</dt>
<dd class="bg1">Gene sets for each species. These files include annotations of
both coding and non-coding genes. This file format is
described <a href="http://www.gencodegenes.org/pages/data_format.html">here</a>.
</dd>

<dt class="bg1">GFF3</dt>
<dd class="bg1">GFF3 provides access to all annotated transcripts which make
up an Ensembl gene set. This file format is
described <a href="http://www.sequenceontology.org/gff3.shtml">here</a>.
</dd>

  );

  $html .= '</dl>';

  return $html;
}

1; 
