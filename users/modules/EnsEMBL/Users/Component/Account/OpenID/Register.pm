package EnsEMBL::Users::Component::Account::OpenID::Register;

### Page displayed to the user when he just logs in for the very first time using openid.
### This page asks user to link any existing user account with the openid login account

### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return sprintf 'Register with %s', shift->site_name;
}

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $login     = $object->fetch_login_from_url_code(1) or return $self->render_message($object->get_message_code('MESSAGE_LOGIN_MISSING'), {'error' => 1});
  my $provider  = $login->provider;
  my $content   = $self->wrapper_div;
  my $form      = $content->append_child($self->new_form({'action' => $hub->url({'action' => 'LinkAccount'})}));

  $form->add_notes(sprintf ('Looks like you are logging in to %s via %s for the very first time. Please check the details and click on continue.', $self->site_name, $provider));

  $form->add_hidden({'name' => 'code', 'value' => $login->get_url_code});

  $form->add_field({
    'label'     => 'Login via',
    'type'      => 'noedit',
    'value'     => $provider,
    'no_input'  => 1
  });

  $self->add_user_details_fields($form, {
    'email'       => $login->email,
    'name'        => $login->name,
    'email_notes' => sprintf('If you already have an account with %s and want to login to that account using your %s login, change this email address to the one already registered with %1$s.', $self->site_name, $provider),
    'button'      => 'Continue'
  });

  return $content->render;
}

1;