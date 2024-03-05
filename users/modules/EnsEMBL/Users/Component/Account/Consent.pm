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

package EnsEMBL::Users::Component::Account::Consent;

### Component for page asking user to consent to GDPR privacy policy

use strict;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $name    = $self->site_name;
  my $old     = $hub->param('old_version');
  my $url     = $hub->species_defs->GDPR_POLICY_URL;

  my $html = qq(
<input type="hidden" class="subpanel_type" value="Consent" />
<h2>$name Privacy Policy</h2><div id="consent_message">);

  if ($old) {
    $html .= qq(
<p>You consented to an earlier version of our policy ($old), which has since been updated.</p>
);
  }

  $html .= qq(
<p>In order to continue using your $name account, you will need to consent to our
current <a href="$url" rel="external">privacy policy</a>.</p>
</div>
);

  ## Use raw HTML for this "form", since we don't want standard formatting
  my $action = $hub->url({'action' => 'UpdateConsent'});
  my $email = $hub->param('email');

  $html .= qq(
<form action="$action" method="post">
<input type="hidden" name="email" value="$email" />
<input type="button" class="fbutton" name="warning" id="consent_warning" value="No thanks" />
<input type="submit" class="fbutton" name="consent_1" value="Accept policy" />
</form>
);

  return $html;
}

1;
