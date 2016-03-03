=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

  my $sd    = $self->species_defs;
  my $here  = $ENV{'REQUEST_URI'};
  my $mobile_link;

  # if you are looking at www on a mobile/tablet device, add mobile site link
  if($ENV{'MOBILE_DEVICE'}) {
    my $mobile_url = "http://".$SiteDefs::MOBILE_URL;
    # not using $you_are_here because not all pages are available on mobile site
    $mobile_link = qq{<a class="mobile-link" href="$mobile_url$here">View Mobile site</a><p></p>};
  }

  return sprintf(
    q(
    <div class="column-two left">
      <p>%s release %d - %s &copy;
        <span class="print_hide"><a href="http://www.sanger.ac.uk/" class="nowrap constant">WTSI</a> /
        <a href="http://www.ebi.ac.uk/" class="nowrap constant">EMBL-EBI</a></span>
        <span class="screen_hide_inline">WTSI / EMBL-EBI<br />http://%s</span>
      </p>
      %s
    </div>
    ),
    $sd->ENSEMBL_SITETYPE, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE, $sd->ENSEMBL_SERVERNAME,
    $mobile_link,
    );
  
}

1;

