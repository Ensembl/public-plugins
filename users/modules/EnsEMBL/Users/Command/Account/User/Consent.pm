=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Command::Account::User::Consent;

### Command module to authenticate the user after verifying the password with the one on records

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $email   = $hub->param('email') || '';
  my $login   = $object->fetch_login_account($email);

  return $self->redirect_login(MESSAGE_EMAIL_NOT_FOUND, {'email' => $email})  unless $login;
  return $self->redirect_login(MESSAGE_VERIFICATION_PENDING)                  unless $login->status eq 'active';
  return $self->redirect_login(MESSAGE_ACCOUNT_BLOCKED)                       unless $login->user->status eq 'active';
  return $self->redirect_login(MESSAGE_PASSWORD_WRONG, {'email' => $email})   unless $login->verify_password($hub->param('password') || '');

  return $self->redirect_after_login($login->user);
}

1;
