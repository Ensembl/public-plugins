package EnsEMBL::Ensembl::Document::HTML::AssemblyTable;

use strict;
use warnings;

use EnsEMBL::Web::RegObj;
use EnsEMBL::Web::Data::Release;
use EnsEMBL::Web::Data::Species;
use Data::Dumper;

{

sub render {
  my ($class, $request) = @_;

  my $SD = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $this_release = $SD->ENSEMBL_VERSION;
  my $archives = $SD->ENSEMBL_ARCHIVES;

  ## get assembly info for each species (including ones no longer in Ensembl
  my $assemblies;
  my @all_species = EnsEMBL::Web::Data::Species->find_all;

  ## Manually add old species that are not in the ensembl_website database
  # Caenorhabditis_briggsae (common name C.briggsae, assembly name cb25.agp8) removed in release 27
  # Apis_mellifera (honeybee) removed in release 39

  ## Split the table in two so it isn't too wide
  my $first_archive = $archive_ids[0];
  my $release_break = int($this_release - (($this_release -$first_archive)/2));

  my $html = render_assembly_table($archives, $assemblies, $this_release, $release_break);
  $html .= "<br />";
  $html .= render_assembly_table($archives, $assemblies, $release_break-1, $first_archive);
  return $html;
}

sub render_assembly_table {
  my ($archives, $assemblies, $start, $end) = @_;

  my $table =  qq(\n<table style="margin:auto; width:95%" border="1" class="ss">\n<tr>$header_row</tr>\n);;

  $table .= qq(</table>\n);
  return $table;
}

}

1;
