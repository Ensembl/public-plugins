package EnsEMBL::Users::Command::Account::Membership::Accept;

### Accepts the membership invitation sent to the logged-in user

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  if ($membership->is_pending_invitation && $membership->user_id eq $self->hub->user->user_id) {
    $membership->activate;
    $self->redirect_url({'action' => 'Groups', 'function' => 'View', 'id' => $membership->group_id});
    return 1;
  }
  return undef;
}

1;