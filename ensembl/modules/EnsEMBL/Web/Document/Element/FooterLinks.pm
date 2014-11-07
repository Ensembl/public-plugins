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

package EnsEMBL::Web::Document::Element::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

use parent qw(EnsEMBL::Web::Document::Element);

sub content {
  return qq(
    <div class="column-two right print_hide">
      <p>
        <a href="http://www.ensembl.info/" class="media-icon"><img src="/i/wordpress.png" title="Ensembl blog" alt="[wordpress logo]" /></a>
        <a href="http://www.facebook.com/Ensembl.org" class="media-icon"><img src="/i/facebook.png" title="Our Facebook page" alt="[Facebook logo]" /></a>
        <a href="http://www.twitter.com/Ensembl" class="media-icon"><img src="/i/twitter.png" title="Follow us on Twitter!" alt="[twitter logo]" /></a>
        <a href="/info/about/index.html" class="constant">About&nbsp;Ensembl</a> | 
        <a href="/info/about/legal/privacy.html" class="constant">Privacy&nbsp;Policy</a> | 
        <a href="/info/about/legal/" class="constant">Disclaimer</a> | 
        <a href="/info/about/contact/" class="constant">Contact&nbsp;Us</a>
      </p>
    </div>
    <div class="column-two right screen_hide_block">
      <p>helpdesk\@ensembl.org</p>
    </div>
  );
}

1;

