package EnsEMBL::Users::Command::Account::Membership::Create;

### Creates the membership object for an invitation sent to a new user (saved in user records)

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  my $user        = $self->hub->user->rose_object;
  my $invitation  = $self->object->fetch_invitation_record_from_url_code;

  if ($invitation) {
    my $email_matching = grep {$_ eq $invitation->email} ($user->email, map {$_->status eq 'active' ? $_->identity : ()} ($user->get_local_login || ()));
  
    if ($email_matching) {
      my $group = $invitation->group;
      if ($group && $group->status eq 'active') {
        my $group_id = $group->group_id;
        $membership->group_id($group_id);
        $invitation->delete;
        $self->redirect_url({'action' => 'Groups', 'function' => 'View', 'id' => $group_id});
        return 1;
      } else {
        ## TODO - error no group found
      }
    } else {
      ## TODO - redirect a page asking for email verification
    }
    return undef;
  } else {
    ## TODO - could not find invitation
  }
}

1;