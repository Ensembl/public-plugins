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

package EnsEMBL::Web::Document::Element::FatFooter;

### Optional fat footer - site-specific, so see plugins 

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
  my $html = '<hr /><div id="fat-footer">';
  my $privacy_url  = $SiteDefs::GDPR_POLICY_URL;
  my $data_preservation_url = $SiteDefs::DATA_PRESERVATION_URL;

  $html .= qq(
              <div class="column-four left">
                <h3>About Us</h3>
                <p><a href="/info/about" rel="nofollow">About us</a></p>
                <p><a href="/info/about/contact/" rel="nofollow">Contact us</a></p>
                <p><a href="/info/about/publications.html" rel="nofollow">Citing Ensembl</a></p>
                <p><a href="$privacy_url" rel="nofollow">Privacy policy</a></p>
                <p><a href="$data_preservation_url" rel="nofollow">Long-term data preservation</a></p>
                <p><a href="/info/about/legal/" rel="nofollow">Disclaimer</a></p>
              </div>
  );


 $html .= qq(
              <div class="column-four left">
                <h3>Get help</h3>
                <p><a href="/info/website/" rel="nofollow">Using this website</a></p>
                <p><a href="/info/website/upload" rel="nofollow">Adding custom tracks</a></p>
                <p><a href="/downloads.html" rel="nofollow">Downloading data</a></p>
                <p><a href="/info/website/tutorials/" rel="nofollow">Video tutorials</a></p>
                <p><a href="/info/docs/tools/vep/" rel="nofollow">Variant Effect Predictor (VEP)</a></p>
              </div>
  );

  $html .= qq(
              <div class="column-four left">
                <h3>Our sister sites</h3>
                <p><a href="http://bacteria.ensembl.org" rel="nofollow">Ensembl Bacteria</a></p>
                <p><a href="http://fungi.ensembl.org" rel="nofollow">Ensembl Fungi</a></p>
                <p><a href="http://plants.ensembl.org" rel="nofollow">Ensembl Plants</a></p>
                <p><a href="http://protists.ensembl.org" rel="nofollow">Ensembl Protists</a></p>
                <p><a href="http://metazoa.ensembl.org" rel="nofollow">Ensembl Metazoa</a></p>
              </div>
  );

  $html .= qq(
              <div class="column-four left">
                <h3>Follow us</h3>
                <p><a class="media-icon" href="http://www.ensembl.info/" rel="nofollow">
                  <img alt="[RSS logo]" title="Ensembl blog" src="/i/rss_icon_16.png"></a>
                  <a href="http://www.ensembl.info/" rel="nofollow">Blog</a></p>
                <p><a class="media-icon" href="http://www.twitter.com/Ensembl" rel="nofollow">
                  <img alt="[twitter logo]" title="Follow us on Twitter!" src="/i/twitter.png"></a>
                    <a href="http://www.twitter.com/ensembl" rel="nofollow">Twitter</a></p>
                <p><a class="media-icon" href="http://www.facebook.com/Ensembl.org" rel="nofollow">
                  <img alt="[Facebook logo]" title="Our Facebook page" src="/i/facebook.png"></a>
                  <a href="http://www.facebook.com/Ensembl.org" rel="nofollow">Facebook</a></p>
              </div>
  );

  $html .= '</div>';

  return $html;
}

1;
