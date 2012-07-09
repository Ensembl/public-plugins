package EnsEMBL::Users::Command::Account::Membership::BlockGroup;

### Block a group from sending further requests to the logged-in user

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  if ($membership->is_pending_invitation && $membership->user_id eq $self->hub->user->user_id) {
    $membership->block_group;
    return 1;
  }
  return undef;
}

1;