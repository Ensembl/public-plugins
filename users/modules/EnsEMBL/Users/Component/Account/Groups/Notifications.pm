package EnsEMBL::Users::Component::Account::Groups::Notifications;

### Notifications component for a logged in user about group invitations or requests
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self  = shift;
  my $user  = $self->hub->user->rose_object;

  return join '', map { sprintf q(<div class="notification %s">%s</div>), $self->_JS_NOTIFICATION, $_ }

    # if a group admin sent an invitation to the user
    map({ $_->is_pending_invitation
      ? sprintf(q{<p><i>%s (%s)</i> is inviting you to join the group <i>%s</i></p><p>%s &middot %s &middot %s</p>},
          map({ $self->html_encode($_->name), $_->email } $_->created_by_user),
          $self->html_encode($_->group->name),
          $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Accept',     'id' => $_->group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Accept'}),
          $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Decline',    'id' => $_->group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Decline'}),
          $self->js_link({'href' => {'action' => 'Membership', 'function' => 'BlockGroup', 'id' => $_->group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Block group from sending further invitations'})
        )
      : ()
    } @{$user->memberships}),

    # if someone requested for membership of a group administrated by the user
    map({ $_->is_pending_request
      ? sprintf(q{<p><i>%s (%s)</i> would like to join your group <i>%s</i></p><p>%s &middot %s &middot %s</p>},
          map({ $self->html_encode($_->name), $_->email } $_->user),
          $self->html_encode($_->group->name),
          $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Allow',      'id' => $_->group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Allow'}),
          $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Ignore',     'id' => $_->group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Ignore'}),
          $self->js_link({'href' => {'action' => 'Membership', 'function' => 'BlockUser',  'id' => $_->group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Block user from sending further requests'})
        )
      : ()
    } map {@{$_->group->memberships}} @{$user->admin_memberships})

  ;
}

1;