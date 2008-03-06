package EnsEMBL::Ensembl::Document::HTML::ArchiveList;

use strict;
use warnings;

use EnsEMBL::Web::RegObj;

{

sub render {
  my ($class, $request) = @_;

  my $SD = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $species = $SD->ENSEMBL_PRIMARY_SPECIES;
  my %archive_info = %{$SD->get_config($species, 'archive')};
  my %archive_to_display = %{$archive_info{'online'}};
  my $html = qq(<h3 class="boxed">List of currently available archives</h3>
<ul class="spaced">);
  my $count = 0;

  foreach my $release (reverse sort keys %archive_to_display) {
    my $subdomain = $archive_to_display{$release};
    (my $date = $subdomain) =~ s/20/ 20/; 
    $html .= qq(<li><strong><a href="http://$subdomain.archive.ensembl.org">Ensembl $release: $date</a>);
    $html .= ' - currently www.ensembl.org' if $release == $SD->ENSEMBL_VERSION;
    $html .= '</strong></li>';
    $count++;
  }

  $html .= "</ul>\n";
  return $html;
}

}

1;
