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

package EnsEMBL::OpenID::Component::Account::LinkExisting;

### Page displayed to the user when he just logs in for the very first time using openid and he chooses to link an existing account to openid account
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_URL_EXPIRED);

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return 'Link existing account';
}

sub content {
  my $self              = shift;
  my $hub               = $self->hub;
  my $object            = $self->object;
  my $login             = $object->fetch_login_from_url_code(1) or return $self->render_message(MESSAGE_URL_EXPIRED, {'error' => 1});
  my $provider          = $login->provider                      or return $self->render_message(MESSAGE_URL_EXPIRED, {'error' => 1});
  my $trusted_provider  = $object->login_has_trusted_provider($login);
  my $form              = $self->new_form({'action' => {'action' => 'OpenID', 'function' => 'Link'}});

  $form->add_notes(sprintf 'Please enter the email address below for your existing %s account.', $self->site_name);

  $form->add_hidden({
    'name'        => 'code',
    'value'       => $login->get_url_code
  });

  $form->add_hidden({
    'name'        => 'trusted_provider',
    'class'       => '_trusted_provider',
    'value'       => $trusted_provider ? '1' : '0'
  });

  $form->add_field({
    'label'       => 'Login via',
    'type'        => 'noedit',
    'value'       => $provider,
    'no_input'    => 1
  });

  $form->add_field({
    'label'       => 'Email address of existing account',
    'type'        => 'email',
    'name'        => 'email',
    'class'       => '_openid_email',
    'value'       => $login->email || '',
    'notes'       => sprintf('<div class="%s">You will need to authenticate that this account belongs to you in the next step.</div>', $trusted_provider ? 'hidden _hide_if_trusted' : '_hide_if_trusted'),
    'required'    => 1
  });

  $form->add_button({'value' => 'Continue'});

  return $self->js_section({'js_panel' => 'AccountForm', 'subsections' => [ $form->render ]});
}

1;
