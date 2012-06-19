package EnsEMBL::Users::Component::Account::Groups::View;

### Page for a logged in user to view details of one of his joined/owned groups
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $user        = $hub->user->rose_object;
  my $group_id    = $hub->param('id');
  my $membership  = $user->get_membership_object($group_id);

  return $self->render_message($object->get_message_code('MESSAGE_GROUP_NOT_FOUND'), {'error' => 1}) unless $membership && $membership->is_active;

  $membership->load('with' => ['group', 'group.records', 'group.memberships']);

  my $group       = $membership->group;
  my $group_name  = $self->html_encode($group->name);
  my $is_admin    = $membership->level eq 'administrator';
  my $refresh_url = $hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group_id});
  my $notif_types = $object->get_notification_types;

  my @sections;

  # group details section
  push @sections, $self->js_section({
    'id'          => "view_group_$group_id",
    'refresh_url' => $refresh_url,
    'heading'     => "Group: $group_name",
    'subsections' => [
      $self->two_column([
        'Group name'  => $group_name,
        'Description' => $self->html_encode($group->blurb),
        'Type'        => $object->get_group_types->{$group->type} || '',
        'Status'      => ucfirst $group->status
      ]),
      '<h3>Notification settings</h3>'.
      $self->two_column([ map { $notif_types->{$_} => $membership->$_ ? 'Yes' : 'No' } $is_admin ? qw(notify_join notify_edit notify_share) : qw(notify_share) ]),
      $self->js_link({
        'href'        => {'action' => 'Groups', 'function' => 'Edit', 'id' => $group_id},
        'caption'     => sprintf('Edit %s', $is_admin ? 'group' : 'settings'),
        'class'       => 'setting'
      }),
      $is_admin
      ? $self->js_link({
        'href'        => {'action' => 'Groups', 'function' => 'Delete', 'id' => $group_id},
        'caption'     => 'Delete group',
        'target'      => 'page',
        'class'       => 'user-group-delete',
        'confirm'     => "You are about to delete the group $group_name. This action can not be undone."
      })
      : $self->js_link({
        'href'        => {'action' => 'Membership', 'function' => 'Unjoin', 'id' => $membership->group_member_id},
        'caption'     => 'Unsubscribe',
        'target'      => 'page',
        'class'       => 'user-group-unjoin',
        'confirm'     => "You are about to remove yourself from the group $group_name. This action can not be undone."
      })
    ]
  });

  # bookmarks section
  my $bookmarks = $group->bookmarks;

  push @sections, $self->js_section({
    'id'          => "group_bookmarks_$group_id",
    'refresh_url' => $refresh_url,
    'subheading'  => 'Bookmarks',
    'subsections' => [
      @$bookmarks ? $self->bookmarks_table({'bookmarks' => $bookmarks, 'type' => 'group'}) : q(<p>There is no bookmark shared with the group.</p>),
      $self->js_link({'href' => {'action' => 'Share', 'function' => 'Bookmark', 'group_id' => $group_id}, 'caption' => 'Share from my bookmarks', 'class' => 'share'})
    ]
  });

  ## annotations
  ## TODO

  ## user data
  ## TODO

  # members
  my $table = $self->new_table(
    [{'key' => 'member', 'title' => 'Member'}, {'key' => 'level', 'title' => 'Level'}, $is_admin ? map {'key' => $_, 'title' => ''}, qw(change_level remove) : ()],
    [],
    {'class' => 'fixed', 'data_table' => 'no_col_toggle', 'exportable' => 0, 'data_table_config' => {'iDisplayLength' => 25}}
  );
  for (@{$group->memberships}) {
    $_->is_active or next;
    my $member          = $_->user or next;
    my $group_member_id = $_->group_member_id;
    my $member_id       = $member->user_id;
    my $member_name     = $self->html_encode($member->name);
    my $member_email    = $member->email;
    my $member_level    = $_->level;
    my $row             = {'member' => $member_name, 'level' => ucfirst $member_level};
    if ($is_admin) {
      if ($member_level ne 'administrator') { # can not remove an admin
        $row->{'remove'} = $self->js_link({
          'href'    => {'action' => 'Membership', 'function' => 'Remove', 'id' => $group_member_id},
          'caption' => 'Remove',
          'confirm' => "Are you sure you want to remove $member_name ($member_email) from the group $group_name?",
          'target'  => 'page',
          'inline'  => 1,
        });
      }
      $row->{'change_level'} = $self->js_link({
        'href'    => {'action' => 'Membership', 'function' => 'Change', 'id' => $group_member_id, 'level' => $member_level eq 'administrator' ? 'member' : 'administrator'},
        'caption' => $member_level eq 'administrator' ? 'Demote to member' : 'Make administrator',
        'confirm' => $member_id eq $user->user_id ? q(Are you sure you want to demote yourself to a member? You won't be able to undo this yourself.) : '',
        'target'  => 'none',
        'inline'  => 1,
      });
      $row->{'member'} .= " ($member_email)";
    }
    $table->add_row($row);
  }

  push @sections, $self->js_section({
    'id'          => "group_members_$group_id",
    'subheading'  => 'Members',
    'refresh_url' => $refresh_url,
    'subsections' => [
      $table->render,
      $is_admin
      ? $self->js_link({'href' => {'action' => 'Group', 'function' => 'Invite', 'id' => $group_id}, 'caption' => 'Invite members', 'class' => 'user-add'})
      : ()
    ]
  });

  return join '', @sections;
}

1;