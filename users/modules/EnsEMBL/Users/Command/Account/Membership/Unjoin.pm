package EnsEMBL::Users::Command::Account::Membership::Unjoin;

### Unjoins the logged-in user from a group

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  if ($membership->user_id eq $self->hub->user->user_id) {
    $self->redirect_url({'action' => 'Groups', 'function' => ''});
    $membership->inactivate;
    return 1;
  }
  return undef;
}

1;