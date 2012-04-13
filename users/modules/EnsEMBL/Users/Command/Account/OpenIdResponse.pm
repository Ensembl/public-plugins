package EnsEMBL::Users::Command::Account::OpenIdResponse;

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $openid_consumer = $object->get_openid_consumer;

  $openid_consumer->handle_server_response(
    'verified'      => sub { $self->handle_verified_identity(@_);               },
    'cancelled'     => sub { $self->redirect_login('OpenIDCancelled');          },
    'not_openid'    => sub { $self->redirect_login('OpenIDInvalid');            },
    'setup_needed'  => sub { $self->redirect_login('OpenIDSetupNeeded');        },
    'error'         => sub { $self->redirect_login('OpenIDError');              },
  );
}

sub handle_verified_identity {
  my ($self, $verified_identity) = @_;
  my ($email, $name);
  my $hub     = $self->hub;
  my $object  = $self->object;

  # Get extension variables
  my $ax = $verified_identity->extension_fields($self->OPENID_EXTENSION_URL_AX);
  if ($ax->{'value.email'}) {
    $email  = $ax->{'value.email'};
    $name   = $ax->{'value.firstname'};

  } else {
    my $sreg = $verified_identity->signed_extension_fields($self->OPENID_EXTENSION_URL_SREG);

    if ($sreg->{'email'}) {
      $email  = $sreg->{'email'};
      $name   = $sreg->{'fullname'};
    }
  }

  $self->handle_openid_login({
    'openid'    => $verified_identity->url,
    'email'     => $email,
    'name'      => $name,
  });
}

1;