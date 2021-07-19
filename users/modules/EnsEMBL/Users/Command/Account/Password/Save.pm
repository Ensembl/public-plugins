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

package EnsEMBL::Users::Command::Account::Password::Save;

### Command module that sets/changes the login password
### This modules is used when
###  1. the user registers with new password after submitting the "confirm email" form
###  2. the user submits the "change password" form
###  3. the user submits the "reset password" form after he clicks on the link in the 'retrieve passord' email
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(
  MESSAGE_PASSWORD_CHANGED
  MESSAGE_PASSWORD_INVALID
  MESSAGE_PASSWORD_MISMATCH
  MESSAGE_PASSWORD_WRONG
  MESSAGE_URL_EXPIRED
);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $login       = $user ? $user->rose_object->get_local_login : $object->fetch_login_from_url_code;
  my $referer     = [ split '/', $hub->param('referer') || '' ];
  my %back_url    = ('species' => '', 'type' => 'Account', 'action' => $referer->[0] || '', 'function' => $referer->[1] || '');
  my $success_url = '';

  if ($user) {
    # If logged-in user trying to change password, and typed in a wrong current password
    return $self->ajax_redirect($hub->url({%back_url, 'err' => MESSAGE_PASSWORD_WRONG})) unless $login->verify_password($hub->param('password'));

  } else {
    # If no login object found - user manually changed the url
    return $self->redirect_message(MESSAGE_URL_EXPIRED, {'error' => 1}) unless $login;
    $back_url{'code'} = $login->get_url_code;
    $success_url      = {'type' => 'Account', 'action' => 'Login', 'msg' => MESSAGE_PASSWORD_CHANGED};
  }

  # Validation
  my $fields = $self->validate_fields({'password' => $hub->param('new_password_1') || '', 'confirm_password' => $hub->param('new_password_2') || ''});

  return $self->ajax_redirect($hub->url({ %back_url, 'err' => $fields->{'invalid'} eq 'password' ? MESSAGE_PASSWORD_INVALID : MESSAGE_PASSWORD_MISMATCH })) if $fields->{'invalid'};

  # If all ok, change/set the password
  $login->set_password($fields->{'password'});

  # If reached here after clicking a link in the email address verification email, we need to activate the login account
  if ($hub->action eq 'Confirmed') {
    $object->activate_user_login($login);
    $self->handle_mailinglist_subscriptions($login);
    return $self->redirect_after_login($login->user);

  # For a password change/reset request
  } else {
    $login->reset_salt_and_save;
    return $self->ajax_redirect($success_url ? $hub->url($success_url) : $hub->PREFERENCES_PAGE);
  }
}

1;
