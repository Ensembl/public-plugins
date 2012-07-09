package EnsEMBL::Users::Command::Account::Membership::Remove;

### Removes a user from the group

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  if ($self->hub->user->rose_object->is_admin_of($membership->group)) {
    $membership->inactivate;
    return 1;
  }
  return undef;
}

1;