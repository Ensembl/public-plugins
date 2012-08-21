package EnsEMBL::Users::Command::Account::RemoveLogin;

### Command module to save details edited by the user
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $user    = $hub->user;

  my $logins  = { map {$_->login_id => $_} @{$user->rose_object->logins} };
  my $login   = delete $logins->{$hub->param('id') || 0};

  if ($login) {

    # can not delete the only login account attached to the user
    return $self->redirect_message($object->get_message_code('MESSAGE_CANT_DELETE_LOGIN')) unless keys %$logins;

    $login->delete;
  }

  return $self->ajax_redirect($hub->url({'action' => 'Preferences'}));
}

1;