package EnsEMBL::Users::Command::Account::Membership::Ignore;

### Ignores a request sent to join the group by a user

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  if ($membership->is_pending_request && $self->hub->user->rose_object->is_admin_of($membership->group)) {
    $membership->inactivate;
    return 1;
  }
  return undef;
}

1;