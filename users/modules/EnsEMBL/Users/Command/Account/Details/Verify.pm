package EnsEMBL::Users::Command::Account::Details::Verify;

### Command to active a user login - user lands on this page after clicking on the link sent to him via email for the purpose of verifying his email
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_VERIFICATION_FAILED);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $login   = $object->fetch_login_from_url_code or return $self->redirect_message(MESSAGE_VERIFICATION_FAILED, {'error' => 1});

  $object->activate_user_login($login);
  return $self->redirect_after_login($login->user);
}

1;