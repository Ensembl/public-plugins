=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::OpenID::Component::Account::Register;

### Page displayed to the user when he just logs in for the very first time using openid.
### This page asks user to confirm his details as provided by the openid provider before continuing

### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_URL_EXPIRED);

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return sprintf 'Register with %s', shift->site_name;
}

sub content {
  my $self              = shift;
  my $hub               = $self->hub;
  my $object            = $self->object;
  my $site_name         = $self->site_name;
  my $login             = $object->fetch_login_from_url_code(1) or return $self->render_message(MESSAGE_URL_EXPIRED, {'error' => 1});
  my $provider          = $login->provider                      or return $self->render_message(MESSAGE_URL_EXPIRED, {'error' => 1});
  my $login_code        = $login->get_url_code;
  my $then_param        = $hub->param('then') || '';
  my $trusted_provider  = $object->login_has_trusted_provider($login);
  my $form              = $self->new_form({'action' => {'action' => 'OpenID', 'function' => 'Add'}});

  $form->add_notes({
    'heading' => sprintf('Already have an %s account?', $site_name),
    'text'    => sprintf('If you already have an account with %s and want to be able to login to that account using your %s login, please <a href="%s">click here</a>.',
      $site_name,
      $provider,
      $hub->url({'action' => 'OpenID', 'function' => 'LinkExisting', 'code' => $login_code})
    )
  });

  $form->add_notes(sprintf 'Looks like you are logging in to %s via %s for the very first time. Please check the details and click on continue.', $self->site_name, $provider);

  $form->add_hidden({
    'name'        => 'code',
    'value'       => $login_code
  });

  $form->add_hidden({
    'name'        => 'trusted_provider',
    'class'       => '_trusted_provider',
    'value'       => $trusted_provider ? '1' : '0'
  });

  $form->add_hidden({
    'name'        => 'then',
    'value'       => $then_param
  }) if $then_param;

  $form->add_field({
    'label'       => 'Login via',
    'type'        => 'noedit',
    'value'       => $provider,
    'no_input'    => 1
  });

  $self->add_user_details_fields($form, {
    'email'       => $login->email,
    'name'        => $login->name,
    'email_notes' => sprintf('<div class="_hide_if_trusted%s">You will recieve an email from %s on this email address for verification.</div>', $trusted_provider ? " hidden" : '', $self->site_name),
    'button'      => 'Continue'
  });

  $form->get_elements_by_name('email')->[0]->set_attribute('class', '_openid_email');

  return $self->js_section({'js_panel' => 'AccountForm', 'subsections' => [ $form->render ]});
}

1;
