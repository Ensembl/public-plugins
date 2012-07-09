package EnsEMBL::Users::Command::Account::Membership::BlockUser;

### Block a user from sending further requests to a group

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  if ($membership->is_pending_request && $self->hub->user->rose_object->is_admin_of($membership->group)) {
    $membership->block_user;
    return 1;
  }
  return undef;
}

1;