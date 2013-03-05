package EnsEMBL::OpenID::Command::Account::Response;

### Handles the response from the openid provider after user tries to login via openid provider's login page
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages; #TODO - add the message constants once openid messages are sorted

use base qw(EnsEMBL::OpenID::Command::Account);

sub process {
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $openid_consumer = $self->get_openid_consumer;
  my %redirect_url    = $hub->user ? qw(type Account action Preferences) : qw(type Account action Login); # TODO - add a 'then' param for Details/View or Preferences page?

  $openid_consumer->handle_server_response(
    'verified'      => sub { $self->handle_verified_identity(@_, \%redirect_url);                                                                         },
    'cancelled'     => sub { $self->ajax_redirect($hub->url({%redirect_url, 'err' => MESSAGE_OPENID_CANCELLED, 'provider' => $hub->param('provider')}));  },
    'not_openid'    => sub { $self->ajax_redirect($hub->url({%redirect_url, 'err' => MESSAGE_OPENID_INVALID }));                                          },
    'setup_needed'  => sub { $self->ajax_redirect($hub->url({%redirect_url, 'err' => MESSAGE_OPENID_SETUP_NEEDED }));                                     },
    'error'         => sub { $self->ajax_redirect($hub->url({%redirect_url, 'err' => MESSAGE_OPENID_ERROR, 'oerr' => $_[1]}));                            }
  );
}

sub handle_verified_identity {
  ## Handles  verified identity after a verification response is received from the openid provider
  my ($self, $verified_identity, $redirect_url) = @_;
  my ($email, $name);

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

  my $hub         = $self->hub;
  my $logged_user = $hub->user;
  my $object      = $self->object;
  my $openid      = $verified_identity->url;
  my $login       = $object->fetch_login_account($openid);
  $email          = $self->validate_fields({'email' => $email || ''})->{'email'} || ''; # just validate the email here, we may throw error later in the code if email is invalid.

  # if request from a logged in user to add login
  if ($logged_user) {

    # if this login object is already linked to a user object
    if ($login && $login->status eq 'active' && (my $login_user = $login->user)) {
      return $self->ajax_redirect($hub->url({%$redirect_url, 'msg' => $login_user->user_id eq $logged_user->user_id ? MESSAGE_LOGIN_ALREADY_LINKED : MESSAGE_LOGIN_ALREADY_TAKEN}));
    }

  # for a login/registration request
  } else {

    # if login account exists - not a first time login
    if ($login) {

      my $linked_user = $login->user;

      unless ($linked_user) { # this means user tried to register previously, but left the process incomplete

        # reset the salt for security reasons
        $login->reset_salt_and_save;
        return $self->redirect_openid_register($login);
      }

      # If blocked user
      return $self->redirect_message(MESSAGE_ACCOUNT_BLOCKED) if $linked_user->status eq 'suspended';

      # For successful login
      return $self->redirect_after_login($linked_user) if $login->status eq 'active';

      # If email provided by openid provider is same as the saved one but user has not verified his email yet, send another verification email
      if ($linked_user->email eq $email) {
        $self->mailer->send_verification_email($login);
        return $self->redirect_message(MESSAGE_VERIFICATION_SENT, {'email' => $email});
      }
    }

    # to continue with registration, we need a valid email
    # very unlikely to happen as the openid server *should not* reply without a valid email
    return $self->redirect_login(MESSAGE_OPENID_EMAIL_MISSING) unless $email;

  }

  # for new registration
  $login ||= $object->new_login_account({
    'type'          => 'openid',
    'identity'      => $openid,
    'status'        => 'pending',
    'provider'      => $hub->param('provider'),
  });

  $login->email($email);
  $login->name($name || '');

  # if not an 'AddLogin' request
  return $self->handle_registration($login, $email) unless $logged_user;

  # add the new login
  my $r_user = $logged_user->rose_object;
  $login->activate($r_user);
  $r_user->save;

  return $self->ajax_redirect($hub->url($redirect_url));
}

1;