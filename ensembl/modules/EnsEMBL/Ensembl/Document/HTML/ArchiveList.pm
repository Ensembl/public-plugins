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

use EnsEMBL::Web::DBSQL::ArchiveAdaptor;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $self = shift;

  ### Use the db adaptor rather than getting the data from config.packed,
  ### otherwise we have to regenerate MULTI.db.packed on all archives every release
  my $adaptor = EnsEMBL::Web::DBSQL::ArchiveAdaptor->new($self->hub);
  my @release_info = @{$adaptor->fetch_releases};
  my $html = qq(<h3 class="boxed">List of currently available archives</h3>
<ul class="spaced">);
  my $count = 0;

  foreach my $release (reverse @release_info) {
    next unless $release->{'online'} eq 'Y';
    my $version = $release->{'id'};
    my $subdomain = $release->{'archive'};
    (my $date = $subdomain) =~ s/20/ 20/; 
    $html .= qq(<li><strong><a href="http://$subdomain.archive.ensembl.org">Ensembl $version: $date</a>);
    ## Assume the first on the list is the live site
    if ($version == $self->hub->species_defs->ENSEMBL_VERSION) {
      $html .= ' - this site';
    }
    elsif ($count == 0) {
      $html .= ' - forwards to www.ensembl.org';
    }
    $html .= '</strong></li>';
    $count++;
  }

  $html .= "</ul>\n";

  $html .= qq(<p><a href="/info/website/archives/assembly.html">Table of archives showing assemblies present in each one</a>.</p>);

  return $html;
}

1;
