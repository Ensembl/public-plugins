package EnsEMBL::Users::Component::Account::Groups::Notifications;

### Notifications component for a logged in user about group invitations or requests
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self  = shift;
  my $user  = $self->hub->user->rose_object;

  # if a group admin sent an invitation to the user
  my @invitations = map({ $_->is_pending_invitation
    ? sprintf(q{<li><i>%s (%s)</i> is inviting you to join the group <i>%s</i><br />%s &middot; %s &middot; %s</li>},
        map({ $self->html_encode($_->name), $_->email } $_->modified_by_user || $_->created_by_user),
        $self->html_encode($_->group->name),
        $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Accept',     'id' => $_->group_member_id, 'csrf_safe' => 1}, 'caption' => 'Accept'}),
        $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Decline',    'id' => $_->group_member_id, 'csrf_safe' => 1}, 'caption' => 'Decline'}),
        $self->js_link({'href' => {'action' => 'Membership', 'function' => 'BlockGroup', 'id' => $_->group_member_id, 'csrf_safe' => 1}, 'caption' => 'Block group from sending further invitations'})
      )
    : ()
    } @{$user->memberships}
  );

  # if someone requested for membership of a group administrated by the user
  my @requests = map({ $_->is_pending_request
    ? sprintf(q{<li><i>%s (%s)</i> would like to join your group <i>%s</i><br />%s &middot; %s &middot; %s</li>},
        map({ $self->html_encode($_->name), $_->email } $_->user),
        $self->js_link({'href' => {'action' => 'Groups',     'function' => 'View',       'id' => $_->group->group_id, 'csrf_safe' => 1}, 'caption' => $self->html_encode($_->group->name)}),
        $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Allow',      'id' => $_->group_member_id, 'csrf_safe' => 1}, 'caption' => 'Allow'}),
        $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Ignore',     'id' => $_->group_member_id, 'csrf_safe' => 1}, 'caption' => 'Ignore'}),
        $self->js_link({'href' => {'action' => 'Membership', 'function' => 'BlockUser',  'id' => $_->group_member_id, 'csrf_safe' => 1}, 'caption' => 'Block user from sending further requests'})
      )
    : ()
    } map {@{$_->group->memberships}} @{$user->admin_memberships}
  );

  return sprintf '%s%s',
    @invitations ? $self->_info($self->append_s_to_plural('Invitation', @invitations > 1), sprintf('<ul>%s</ul>', join('', @invitations)), '100%') : '',
    @requests    ? $self->_info($self->append_s_to_plural('Request',    @requests    > 1), sprintf('<ul>%s</ul>', join('', @requests   )), '100%') : ''
  ;
}
1;