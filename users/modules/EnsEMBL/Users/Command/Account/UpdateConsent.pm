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

package EnsEMBL::Users::Command::Account::UpdateConsent;

## If user consents to privacy policy, update account and return to original web page,
## otherwise redirect to warning that their account will be disabled

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $hub     = $self->hub;
  my $email   = $hub->param('email') || '';
  my $login   = $self->object->fetch_login_account($email);

  if ($hub->param('consent_1')) {
    $login->update_consent($hub->species_defs->GDPR_VERSION);
    return $self->redirect_after_login($login->user);
  }
  else {
    $login->disable;
    ## Redirect without user, so no cookie is set
    return $self->redirect_after_login;
  }

}

1;
