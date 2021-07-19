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

package EnsEMBL::OpenID::Component::Account::Authenticate;

### Page displayed to ask the user to authorise his existing account when he logs in for the very first time using openid and he chooses to link an existing account to openid login
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_NO_EXISTING_ACCOUNT MESSAGE_URL_EXPIRED);

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return 'Authenticate existing account';
}

sub content {
  my $self              = shift;
  my $hub               = $self->hub;
  my $object            = $self->object;
  my $email             = $hub->param('email')                    or return $self->render_message(MESSAGE_URL_EXPIRED,          {'error' => 1});
  my $existing_user     = $object->fetch_user_by_email($email)    or return $self->render_message(MESSAGE_NO_EXISTING_ACCOUNT,  {'error' => 1});
  my $login             = $object->fetch_login_from_url_code(1)   or return $self->render_message(MESSAGE_URL_EXPIRED,          {'error' => 1});
  my $provider          = $login->provider                        or return $self->render_message(MESSAGE_URL_EXPIRED,          {'error' => 1});
  my $site_name         = $self->site_name;
  my $form              = $self->new_form({'action' => {'action' => 'OpenID', 'function' => 'Link'}});

  $form->add_notes("To enable us to link your $provider account to your existing $site_name account, we need to make sure that the existing account belongs to you.");
  $form->add_hidden({'name' => 'code',            'value' => $login->get_url_code });
  $form->add_hidden({'name' => 'email',           'value' => $email               });
  $form->add_hidden({'name' => 'authentication',  'value' => 'email'              });

  if ($existing_user->get_local_login) {
    $form->add_field({
      'label'       => 'Please choose a method for account verification',
      'type'        => 'radiolist',
      'name'        => 'authentication',
      'values'      => [{
        'value'       => 'email',
        'caption'     => "Send an email on $email", 
        'checked'     => 1
      }, {
        'value'       => 'password',
        'caption'     => "Authenticate via $site_name password for this account",
        'class'       => '_password_auth'
      }]
    });

    $form->add_field({
      'field_class' => 'hidden _password_auth', # displayed by JavaScript only if user chooses for password authentication
      'label'       => 'Password',
      'type'        => 'password',
      'name'        => 'password',
      'notes'       => 'Please enter the password for the existing account.'
    });

  } else {
    $form->add_notes("An email will be sent to $email asking for the verification of this existing $site_name account.");
  }

  $form->add_button({'value' => 'Continue'});

  return $self->js_section({'subsections' => [ $form->render ], 'js_panel' => 'AccountForm'});
}

1;
