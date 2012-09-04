package EnsEMBL::Users::Command::Account::Group::Join;

### Command module to enable user to join (or send request to) a group
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;

  if (my $group = $object->fetch_group($hub->param('id'))) {

    my $group_type = $group->type;
    if ($group_type ne 'private') {
      my $membership = $group->membership($user);
      my $action;

      if ($membership->is_user_blocked || $membership->is_active) {
        return $self->ajax_redirect($self->internal_referer);

      } elsif ($membership->is_pending_invitation || $group_type eq 'open') {
        $membership->activate;

      } else {
        $membership->make_request;
      }

      # notify admins
      $self->send_group_joining_notification_email($user, $group, $membership->is_active);

      $membership->save(user => $user);
      return $self->ajax_redirect($group_type eq 'open' ? $hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id}) : $self->internal_referer);
    }
  }

  return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'List', 'err' => MESSAGE_GROUP_NOT_FOUND}));
}

1;
