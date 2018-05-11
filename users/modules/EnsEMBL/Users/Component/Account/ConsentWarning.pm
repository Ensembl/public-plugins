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

package EnsEMBL::Users::Component::Account::ConsentWarning;

### Component for page that warns the user their account is about to be disabled

use strict;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $name    = $self->site_name;

  my $html = qq(
<h2>Account Deactivation</h2>
<p><b>IMPORTANT</b>: Since you have chosen not to agree to our privacy policy,
your account will be disabled and we will delete it within 30 days unless otherwise
notified. Are you sure you wish to do this?</p>
);


## Use raw HTML for this "form", since we don't want standard formatting
  my $action = $hub->url({'action' => 'UpdateConsent'});
  my $email = $hub->param('email');

  $html .= qq(
<form action="$action" method="post">
<input type="hidden" name="email" value="$email" />
<input type="submit" class="fbutton" name="consent_0" value="Yes, disable my account" />
<input type="submit" class="fbutton" name="consent_1" value="Accept privacy policy" />
</form>
);

  return $html;
}

1;
