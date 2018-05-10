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

package EnsEMBL::Users::Component::Account::Consent;

### Component for page asking user to consent to GDPR privacy policy

use strict;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $name    = $self->site_name;

  my $yes_url = $hub->url({'action' => 'UpdateConsent', 'consent' => 1});
  my $no_url  = $hub->url({'action' => 'UpdateConsent', 'consent' => 0});

  my $html = qq(
<h2>$name Privacy Policy</h2>
<p>In order to continue using your $name account, you will need to consent to our
<a href="/info/about/legal/privacy.html" rel="external">privacy policy</a>.</p>
<div style="text-align:center">
  <a href="$no_url" class="button">No thanks</a>
  <a href="$yes_url" class="button">Accept policy</a>
</div>
);

  return $html;
}

1;
