package EnsEMBL::Users::Command::Account::Membership::Change;

### Changes the level of a user's membership

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_CANT_DEMOTE_ADMIN);

use base qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;
  my $hub   = $self->hub;
  my $group = $membership->group;
  my $admin = $hub->user->rose_object;
  my $url   = {'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id};

  if ($admin->is_admin_of($group)) {
    if ($membership->user_id eq $admin->user_id && scalar @{$group->admin_memberships} == 1) { # the only admin of the group can't demote himself
      $self->redirect_url({
        'action'  => 'Message',
        'err'     => MESSAGE_CANT_DEMOTE_ADMIN,
        'back'    => $hub->url($url)
      });
    } else {
      $membership->level($hub->param('level') eq 'administrator' ? 'administrator' : 'member');
      $self->redirect_url($url);
      return 1;
    }
  }
  return undef;
}

1;
