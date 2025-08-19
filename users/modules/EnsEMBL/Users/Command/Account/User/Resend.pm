=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2025] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Command::Account::User::Resend;

### Command module to resend verification email for pending accounts

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(
  MESSAGE_ALREADY_REGISTERED
  MESSAGE_EMAIL_INVALID
  MESSAGE_EMAIL_NOT_FOUND
  MESSAGE_VERIFICATION_SENT
  MESSAGE_VERIFICATION_NOT_SENT
  MESSAGE_UNKNOWN_ERROR
);

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $email   = $hub->param('email') || '';

  # Validation
  my $fields  = $self->validate_fields({'email' => $email});
  return $self->redirect_message(MESSAGE_EMAIL_INVALID, {'error' => 1}) if $fields->{'invalid'};

  # Get the existing account
  $email      = $fields->{'email'};
  my $login   = $object->fetch_login_account($email);
  return $self->redirect_message(MESSAGE_EMAIL_NOT_FOUND, {'email' => $email, 'error' => 1}) unless $login;

  # Check account status
  if ($login->status eq 'pending') {
    # Reset the salt to generate a new verification code
    $login->reset_salt_and_save;
    
    # Send verification email
    my $sent = $self->mailer->send_verification_email($login);
    
    if ($sent) {
      return $self->redirect_message(MESSAGE_VERIFICATION_SENT, {'email' => $email});
    } else {
      return $self->redirect_message(MESSAGE_VERIFICATION_NOT_SENT);
    }
  } elsif ($login->status eq 'active') {
    # If already active, redirect to login
    return $self->redirect_login(undef, {'email' => $email, 'msg' => MESSAGE_ALREADY_REGISTERED});
  } else {
    # For other statuses (disabled/blocked), redirect to contact helpdesk
    return $self->redirect_message(MESSAGE_UNKNOWN_ERROR, {'error' => 1});
  }
}

1;
