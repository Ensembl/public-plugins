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

package EnsEMBL::Web::Document::HTML::SpeciesPage;

### Renders the content of the  "Find a species page" linked to from the SpeciesList module

use strict;

use EnsEMBL::Web::Document::Table;
use EnsEMBL::Web::Utils::FormatText qw(glossary_helptip);

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my ($self, $request) = @_;

  my $hub           = $self->hub;
  my $species_defs  = $hub->species_defs;
  my $version       = $species_defs->ENSEMBL_VERSION;
  my $sitename      = $species_defs->ENSEMBL_SITETYPE;
  my $static_server = $species_defs->ENSEMBL_STATIC_SERVER;

  ## Get current Ensembl species
  my @valid_species = $species_defs->valid_species;
  my @new_species   = @{$species_defs->multi_val('NEW_SPECIES')||[]};
  my %species;

  foreach my $sp (@valid_species) {
    my $species_name = ucfirst($species_defs->get_config($sp, 'STRAIN_GROUP')
                        || $species_defs->get_config($sp, 'SPECIES_DB_NAME')
                        || $species_defs->get_config($sp, 'SPECIES_PRODUCTION_NAME'));
    ## Remove any assembly accession from chosen name
    $species_name =~ s/_gca\d+//;
    $species_name =~ s/v\d+$//;
    my $info    = {
        'dir'           => $sp,
        'image'         => $species_defs->get_config($sp, 'SPECIES_IMAGE'),
        'status'        => 'live',
        'is_new'        => 0,
        'url'           => $species_defs->get_config($sp, 'SPECIES_URL'),
        'species_name'  => $species_name,
        'sci_name'      => $species_defs->get_config($sp, 'SPECIES_SCIENTIFIC_NAME'),
        'prod_name'     => $species_defs->get_config($sp, 'SPECIES_PRODUCTION_NAME'),
        'common_name'   => $species_defs->get_config($sp, 'SPECIES_COMMON_NAME'),
        'strain'        => $species_defs->get_config($sp, 'SPECIES_STRAIN'),
        'assembly'      => $species_defs->get_config($sp, 'ASSEMBLY_NAME'),
        'accession'     => $species_defs->get_config($sp, 'ASSEMBLY_ACCESSION'),
        'taxon_id'      => $species_defs->get_config($sp, 'TAXONOMY_ID'),
        'clade'         => $species_defs->get_config($sp, 'SPECIES_GROUP'),
        'provider'      => $species_defs->get_config($sp, 'ANNOTATION_PROVIDER_NAME'),
        'variation'     => $species_defs->get_config($sp,'databases')->{'DATABASE_VARIATION'},
        'regulation'    => $species_defs->get_config($sp,'databases')->{'DATABASE_FUNCGEN'},
    };
    if (grep {$info->{'prod_name'} eq $_} @new_species) {
      $info->{'is_new'} = 1;
    }
    $species{$sp} = $info;
  }

  ## Display all the species in data table
  my $html;

  $html .= '<div class="js_panel" id="species-table">
      <input type="hidden" class="panel_type" value="Content">';

  my $columns = $self->table_columns();
  my $table = EnsEMBL::Web::Document::Table->new($columns, [], { data_table => 1, exportable => 1 });
  $table->code        = 'SpeciesTable::99';
  
  $table->filename = 'Species';
  
  my %labels = $species_defs->multiX('TAXON_LABEL');

  foreach my $info (sort {$a->{'sci_name'} cmp $b->{'sci_name'}} values %species) {
    next unless $info;
    my $dir       = $info->{'dir'};
    next unless $dir;
    my $clade     = $labels{$info->{'clade'}};

    my $img_url = '/';
    my $strain_name = ($info->{'strain'} && $info->{'strain'} ne 'reference') 
                        ? sprintf(' (%s)', $info->{'strain'}) : '';
    my $sp_link    = sprintf('<a href="/%s" class="bigtext"><i>%s</i>%s</a>', 
                            $dir, $info->{'sci_name'}, $strain_name);

    ## Species stats
    my $db_adaptor = $self->hub->database('core', $dir);
    my $genome_container = $db_adaptor->get_GenomeContainer();
    my $genome_size = $self->thousandify($genome_container->get_ref_length());
    my ($coding, $noncoding) = (0,0);
    foreach my $stat (@{$genome_container->fetch_all_statistics()}) {
      my $name = $stat->statistic;
      next unless $name =~ /coding_cnt/;
      if ($name eq 'coding_cnt') {
        $coding = $stat->value;
      }
      else { ## Add up all non-coding stats
        $noncoding += $stat->value;
      }
    }

    ## FTP links
    my $ftp         = $species_defs->ENSEMBL_FTP_URL;
    my $sub_dir     = sprintf 'species/%s/%s', $info->{'species_name'}, $info->{'accession'};
    my $databases   = $species_defs->get_config($info->{'url'}, 'databases');
    my $geneset     = $species_defs->get_config($info->{'url'}, 'LAST_GENESET_UPDATE');
    $geneset        =~ s/-/_/g;

    my $annotation  = sprintf('<a rel="external" href="%s/%s/geneset/%s/">FASTA/GTF/GFF3/TSV</a>', $ftp, $sub_dir, $geneset);
    my $genome      = sprintf('<a rel="external" href="%s/%s/genome/">FASTA</a>', $ftp, $sub_dir);
    my $rnaseq      = $databases->{'DATABASE_RNASEQ'} 
                        ? sprintf('<a rel="external" href="%s/%s/rnaseq/">BAM</a>', $ftp, $sub_dir)
                        : '';

    $table->add_row({
      'species'     => sprintf('<a href="%s%s/"><img src="/i/species/%s.png" alt="%s" class="badge-48" style="float:left;padding-right:4px" /></a>%s',
                        $img_url, $dir,  $info->{'image'}, $clade, $sp_link),
      'is_new'      => $info->{'is_new'} ? 'NEW' : '',
      'common'      => $info->{'common_name'}, 
      'clade'       => $clade,
      'taxon_id'    => $info->{'taxon_id'},
      'assembly'    => $info->{'assembly'},
      'size'        => $genome_size,
      'accession'   => $info->{'accession'},
      'provider'    => $info->{'provider'},
      'annotation'  => $annotation,
      'genome'      => $genome,
      'rnaseq'      => $rnaseq,
    });

  }
  $html .= $table->render;
  $html .= '</div>';
  return $html;  
}

sub table_columns {
  my $self = shift;
  my $sd = $self->hub->species_defs; 

  my $columns = [
      { key => 'species',     title => 'Scientific name',       width => '25%', align => 'left', sort => 'string' },
      { key => 'is_new',     title => 'New',                    width => '5%', align => 'left', sort => 'string' },
      { key => 'common',      title => 'Common name',           width => '15%', align => 'left', sort => 'html'},
      { key => 'clade',       title => 'Clade',                 width => '5%', align => 'left', sort => 'html' },
      { key => 'taxon_id',    title => 'Taxon ID',              width => '5%', align => 'left', sort => 'numeric', 'hidden' => 1 }, 
      { key => 'assembly',    title => 'Assembly name',      width => '5%', align => 'left', 'hidden' => 1  },
      { key => 'accession',   title => 'Accession',             width => '5%', align => 'left' },
      { key => 'size',        title => 'Genome size (bps)',     width => '5%', align => 'left', sort => 'numeric', 'hidden' => 1  },
      { key => 'provider',    title => 'Annotation provider',   width => '10%', align => 'left' },
      { key => 'annotation',  title => 'Annotation',            width => '5%', align => 'left' },
      { key => 'genome',      title => 'Genome',                width => '5%', align => 'left' },
      { key => 'rnaseq',      title => 'RNA Seq',               width => '5%', align => 'left' },
  ];

  return $columns;
}

1;
