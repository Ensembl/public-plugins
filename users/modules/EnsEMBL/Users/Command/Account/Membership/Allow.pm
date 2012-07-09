package EnsEMBL::Users::Command::Account::Membership::Allow;

### Allows a user to join a group

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  if ($membership->is_pending_request && $self->hub->user->rose_object->is_admin_of($membership->group)) {
    $membership->activate;
    return 1;
  }
  return undef;
}

1;