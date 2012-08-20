package EnsEMBL::Users::Command::Account::Group::Save;

### Command module to save group details edited by the logged in admin
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $group_id    = $hub->param('group_id');

  my $membership  = $group_id
    ? $object->fetch_accessible_membership_for_user($user->rose_object, $group_id)
    : $user->rose_object->create_new_membership_with_group
    or return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'Edit', 'err' => $object->get_message_code('MESSAGE_GROUP_NOT_FOUND')}));

  my $group       = $membership->group;

  if ($membership->level eq 'administrator') {

    # Changes to group object
    my $original_values = $group_id ? { map { $_ => $group->$_ } qw(name type blurb status) } : {};

    $group->name($hub->param('name') || sprintf(q(%s's group), $user->name));
    $group->type($hub->param('type') =~ /^(open|private)$/ ? $hub->param('type') : 'restricted');
    $group->blurb($hub->param('blurb'));
    $group->status($hub->param('status') eq 'inactive' ? 'inactive' : 'active');
    $group->save('user' => $user);

    my $modified_values = $group_id ? { map { $_ => $group->$_ } qw(name type blurb status) } : {};

    # do we need to notify anyone about the changes?
    $self->send_group_editing_notification_email($user, $group, $original_values, $modified_values);

    # Changes to membership object
    $membership->$_($hub->param($_)) for qw(notify_join notify_edit notify_share);

  } else {

    $membership->notify_share($hub->param('notify_share'));
  }

  $membership->group_id($group->group_id);
  $membership->save('user' => $user);

  return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id}));
}

1;