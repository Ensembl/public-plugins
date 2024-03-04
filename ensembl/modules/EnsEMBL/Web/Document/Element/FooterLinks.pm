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

package EnsEMBL::Web::Document::Element::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

use URI::Escape qw(uri_escape);

use parent qw(EnsEMBL::Web::Document::Element);

sub content {
  my $self = shift;

  my $html = qq(<div class="column-two right print_hide"><p>);

  unless ($ENV{'ENSEMBL_TYPE'} =~ /Help|Account|UserData|Tools/) {

    my $sd = $self->species_defs;

    my $you_are_here = $ENV{'REQUEST_URI'};
    my $stable_URL   = uri_escape('http://' . $sd->ARCHIVE_VERSION . '.archive.ensembl.org');

    $html .= qq{
        <a class="modal_link" id="p_link" href="/Help/Permalink?url=$stable_URL">Permanent link</a>
    };

    unless ($you_are_here =~ /html$/ && $you_are_here ne '/index.html') {
      ## Omit archive links from static content, which tends to change a lot
      $html .= ' - <a class="modal_link" id="a_link" href="/Help/ArchiveList">View in archive site</a>';
    }

    ## Hack to avoid replicating this entire module in our archive plugin just for one link!
    if ($sd->ENSEMBL_SERVERNAME =~ /archive/) {
      $html .= qq( - <a href="http://www.ensembl.org$you_are_here">View in current Ensembl</a>);
    }
  }

  $html .= '</p></div>';
  return $html;
}

1;

