=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::Copyright;

### Replacement copyright notice for www.ensembl.org

use strict;

use URI::Escape qw(uri_escape);

use parent qw(EnsEMBL::Web::Document::Element);

sub new {
  return shift->SUPER::new({
    %{$_[0]},
    sitename => '?'
  });
}

sub sitename    :lvalue { $_[0]{'sitename'};   }

sub content {
  my $self = shift;
  my @time = localtime();
  my $year = @time[5] + 1900;
  my $html;

  my $sd = $self->species_defs;

  my $you_are_here = $ENV{'REQUEST_URI'};
  my $stable_URL   = uri_escape('http://' . $sd->ARCHIVE_VERSION . '.archive.ensembl.org');

  $html .= sprintf(
    q(
    <div class="column-two left">
      <p>%s release %d - %s &copy;
        <span class="print_hide"><a href="http://www.sanger.ac.uk/" class="nowrap constant">WTSI</a> /
        <a href="http://www.ebi.ac.uk/" class="nowrap constant">EMBL-EBI</a></span>
        <span class="screen_hide_inline">WTSI / EMBL-EBI<br />http://%s</span>
      </p>
    ),
    $sd->ENSEMBL_SITETYPE, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE, $sd->ENSEMBL_SERVERNAME,
    );
  
  $html .= '<p class="print_hide">'; 

  unless ($ENV{'ENSEMBL_TYPE'} =~ /Help|Account|UserData|Tools/) {

    # if you are looking at www on a mobile/tablet device, add mobile site link
    if($ENV{'MOBILE_DEVICE'}) {
      # not using $you_are_here because not all pages are available on mobile site
      $html .= qq{<a class="mobile_link" href="http://m.ensembl.org">Mobile site</a> - };
    }

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

