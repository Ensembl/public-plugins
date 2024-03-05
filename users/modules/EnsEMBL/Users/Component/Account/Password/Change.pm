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

package EnsEMBL::Users::Component::Account::Password::Change;

### Create a form for the user to be able to change his password
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_URL_EXPIRED);

use parent qw(EnsEMBL::Users::Component::Account);

sub caption {
  return shift->hub->user ? 'Change Password' : 'Reset Password';
}

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;

  my $user      = $hub->user;
  my $login     = $user ? $user->rose_object->get_local_login : $object->fetch_login_from_url_code;

  # If no login object found - user manually changed the url
  return $self->render_message(MESSAGE_URL_EXPIRED, {'error' => 1}) unless $login;

  my $form      = $self->new_form({'action' => {qw(action Password function Save)}, 'csrf_safe' => 1});

  $form->add_field({'type' => 'noedit', 'name' => 'email', 'label' => 'Login email', 'no_input' => 1, 'value' => $login->identity });

  if ($user) {
    $form->add_field({'type' => 'password', 'name' => 'password', 'label' => 'Current password', 'required' => 1});
  } else {
    $form->add_hidden({'name' => 'code', 'value' => $login->get_url_code });
  }

  $form->add_hidden({'name'   => $self->_JS_CANCEL, 'value' => $hub->PREFERENCES_PAGE}) if $user;
  $form->add_field({'type'    => 'password',  'name'  => 'new_password_1', 'label'  => 'New password',              'required' => 1,  'notes' => 'at least 6 characters'});
  $form->add_field({'type'    => 'password',  'name'  => 'new_password_2', 'label'  => 'Confirm new password',      'required' => 1});
  $form->add_field({'inline'  => 1, 'elements' => [
    {'type' => 'Submit', 'name'  => 'submit', 'value'  => $user ? 'Change' : 'Reset' },
    {'type' => 'Reset',  'name'  => 'reset',  'value'  => 'Cancel', 'class' => $self->_JS_CANCEL }
  ]});

  return $self->js_section({'subsections' => [ $form->render ]});
}

1;
