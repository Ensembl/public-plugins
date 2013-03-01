package EnsEMBL::OpenID::Command::Account::Request;

### Packs the openid request object and redirects the browser to openid provider's login page
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_OPENID_ERROR);

use base qw(EnsEMBL::OpenID::Command::Account);

sub process {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $then_param  = $hub->param('then');
  my $provider    = $hub->param('provider');
  my $openid_url  = $self->get_openid_url($provider, $hub->param('username') || '');
  my $consumer    = $self->get_openid_consumer;
  my $claimed_id  = $consumer->claimed_identity($openid_url);
  my $root        = $object->get_root_url;

  if ($claimed_id) {

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
  
    return $self->ajax_redirect($claimed_id->check_url(
      'delayed_return'  => 1,
      'return_to'       => $root.$hub->url({'action' => 'OpenID', 'function' => 'Response', 'provider' => $provider, $then_param ? ('then' => $then_param) : ()}),
      'trust_root'      => $root
    ));

  }

  return $self->redirect_login(MESSAGE_OPENID_ERROR, {'oerr' => $consumer->errtext});
}

sub get_openid_url {
  ## Returns a URI for making an openid request
  ## @param Provider name
  ## @param User name (optional) - required for the openid serive proivider that do not do a "discovery" of the user
  ## @return string uri
  my ($self, $provider, $username) = @_;

  my $openid_providers = $self->object->openid_providers;

  while (my ($key, $value) = splice @$openid_providers, 0, 2) {
    if ($key eq $provider) {
      (my $url = $value->{'url'}) =~ s/\[USERNAME\]/$username/;
      return $url;
    }
  }
}

1;