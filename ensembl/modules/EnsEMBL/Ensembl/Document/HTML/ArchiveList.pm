=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Ensembl::Document::HTML::ArchiveList;

use strict;
use warnings;

use EnsEMBL::Web::RegObj;

{

sub render {
  my ($class, $request) = @_;

  my $SD = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $species = $SD->ENSEMBL_PRIMARY_SPECIES;
  my %archive_info = %{$SD->ENSEMBL_ARCHIVES};
  my $html = qq(<h3 class="boxed">List of currently available archives</h3>
<ul class="spaced">);
  my $count = 0;

  foreach my $release (reverse sort keys %archive_info) {
    next if $release > $SD->ENSEMBL_VERSION; ## In case this is a dev site on a yet-to-be-released version
    my $subdomain = $archive_info{$release};
    (my $date = $subdomain) =~ s/20/ 20/; 
    $html .= qq(<li><strong><a href="http://$subdomain.archive.ensembl.org">Ensembl $release: $date</a>);
    $html .= ' - currently www.ensembl.org' if $release == $SD->ENSEMBL_VERSION;
    $html .= '</strong></li>';
    $count++;
  }

  $html .= "</ul>\n";

  $html .= qq(<p><a href="/info/website/archives/assembly.html">Table of archives showing assemblies present in each one</a>.</p>);

  return $html;
}

}

1;
