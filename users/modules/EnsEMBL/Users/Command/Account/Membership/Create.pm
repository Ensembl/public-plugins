package EnsEMBL::Users::Command::Account::Membership::Create;

### Creates the membership object for an invitation sent to a new user (saved in user records)
### Membership created is a "pending" invitation

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND MESSAGE_URL_EXPIRED);

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  my %redirect_url  = qw(type Account action Groups);
  my $return        = undef;
  my $invitation    = $self->object->fetch_invitation_record_from_url_code;

  if ($invitation) {

    # we do not check if the email to which the invitation was sent is same as user's email as user can have a different registered email
    my $group = $invitation->group;
    if ($group && $group->status eq 'active') {
      my $group_id = $group->group_id;
      $membership->group_id($group_id);
      $membership->make_invitation;
      $invitation->delete;
      $return = 1;
    } else {
      $redirect_url{'err'} = MESSAGE_GROUP_NOT_FOUND;
    }
  } else {
    $redirect_url{'err'} = MESSAGE_URL_EXPIRED;
  }
  $self->redirect_url(\%redirect_url);
  return $return;
}

1;