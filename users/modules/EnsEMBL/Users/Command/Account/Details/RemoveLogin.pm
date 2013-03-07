package EnsEMBL::Users::Command::Account::Details::RemoveLogin;

### Command module to remove a login object linked to the user
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_CANT_DELETE_LOGIN);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $hub     = $self->hub;
  my $user    = $hub->user;

  my $logins  = { map {$_->login_id => $_} @{$user->rose_object->logins} };
  my $login   = delete $logins->{$hub->param('id') || 0};

  if ($login) {

    # can not delete the only login account attached to the user, or any login of type other than openid or local
    return $self->redirect_message(MESSAGE_CANT_DELETE_LOGIN) unless keys %$logins && $login->type =~ /^(openid|local)$/;

    $login->delete;
  }

  return $self->ajax_redirect($hub->PREFERENCES_PAGE);
}

1;