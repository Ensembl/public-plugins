package EnsEMBL::Users::Command::Account::OpenID;

### Base class for OpenID::Request && OpenID::Response classes
### @author hr5

use strict;
use warnings;

use Net::OpenID::Consumer;
use LWP::UserAgent;

use base qw(EnsEMBL::Users::Command::Account);

use constant {
  OPENID_EXTENSION_URL_AX   => 'http://openid.net/srv/ax/1.0',
  OPENID_EXTENSION_URL_SREG => 'http://openid.net/extensions/sreg/1.1',
};

sub get_openid_consumer {
  ## Gets the openid consumer object used for openid login process
  ## @return Net::OpenID::Consumer
  my $self    = shift;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $ua      = LWP::UserAgent->new;

  $ua->proxy([qw(http https)], $_) for $sd->ENSEMBL_WWW_PROXY || ();

  return Net::OpenID::Consumer->new(
    'ua'              => $ua,
    'required_root'   => $self->object->get_root_url,
    'args'            => $hub->input,
    'consumer_secret' => $sd->OPENID_CONSUMER_SECRET,
  );
}

1;