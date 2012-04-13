package EnsEMBL::Users::Command::Account::OpenIdRequest;

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $provider    = $hub->function;
  my $openid_url  = $object->get_openid_url($provider, $hub->param('user') || '');
  my $claimed_id  = $object->get_openid_consumer->claimed_identity($openid_url);
  my $root        = $object->get_root_url;

  # For OpenID 2.0
  $claimed_id->set_extension_args($self->OPENID_EXTENSION_URL_AX, {
    'mode'            => 'fetch_request',
    'required'        => 'email,firstname',
    'type.email'      => 'http://axschema.org/contact/email',
    'type.firstname'  => 'http://axschema.org/namePerson/first'
  });

  # For older versions
  $claimed_id->set_extension_args($self->OPENID_EXTENSION_URL_SREG, {
    'required'        => 'email,firstname',
  });

  $self->ajax_redirect($claimed_id->check_url(
    'delayed_return'  => 1,
    'return_to'       => $root.$hub->url({'action' => 'OpenIdResponse', 'function' => $provider}),
    'trust_root'      => $root
  ));
}

1;