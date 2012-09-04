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
  my $membership  = $object->fetch_accessible_membership_for_user($user, $group_id, {'with_objects' => ['group', 'group.records', 'group.memberships', 'group.memberships.user']});

  if ($membership) {

    my $group       = $membership->group;
    my $group_name  = $self->html_encode($group->name);
    my $is_admin    = $membership->level eq 'administrator';
    my $refresh_url = $hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group_id});
    my $notif_types = $self->get_notification_types;

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
          'Type'        => $self->get_group_types->{$group->type} || '',
          'Status'      => ucfirst $group->status
        ]),
        '<h3>Notification settings</h3>'.
        $self->two_column([ map { $notif_types->{$_} => $membership->$_ ? 'Yes' : 'No' } $is_admin ? qw(notify_join notify_edit notify_share) : qw(notify_share) ]),
        $self->js_link({
          'href'        => {'action' => 'Groups', 'function' => 'Edit', 'id' => $group_id},
          'caption'     => 'Edit settings',
          'class'       => 'setting'
        }),
        $is_admin
        ? $self->js_link({
          'href'        => {'action' => 'Group', 'function' => 'Delete', 'id' => $group_id},
          'caption'     => 'Delete group',
          'target'      => 'page',
          'class'       => 'user-group-delete',
          'confirm'     => "You are about to delete the group $group_name. This action can not be undone. Alternatively, click 'cancel' and you can set this group to 'inactive' by editing settings."
        })
        : $self->js_link({
          'href'        => {'action' => 'Membership', 'function' => 'Unjoin', 'id' => $membership->group_member_id},
          'caption'     => 'Unsubscribe',
          'target'      => 'page',
          'class'       => 'user-group-unjoin',
          'confirm'     => "You are about to remove yourself from the group &quot;$group_name&quot;. This action can not be undone."
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
        @$bookmarks ? $self->bookmarks_table({'bookmarks' => $bookmarks, 'group' => $group_id}) : q(<p>There is no bookmark shared with the group.</p>),
        $self->js_link({'href' => {'action' => 'Share', 'function' => 'Bookmark', 'group' => $group_id}, 'caption' => 'Share from my bookmarks', 'class' => 'share'})
      ]
    });

    ## annotations
    ## TODO

    ## user data
    ## TODO

    # members
    $group->load('with' => [ 'memberships', 'memberships.user' ]);
    my @memberships = grep {$_->user} @{$group->memberships};

    my $table = $self->new_table([
      {'key' => 'member',   'title' => 'Member',  'width' => '30%'                    },
      {'key' => 'level',    'title' => 'Level',   'width' => $is_admin ? '20%' : '70%'},
      $is_admin ?
      {'key' => 'buttons',  'title' => '',        'width' => '50%'                    } : ()
    ], [], {'data_table' => 'no_col_toggle', 'exportable' => 0, 'data_table_config' => {'iDisplayLength' => 25}});

    for (sort {$a->user->name cmp $b->user->name} @memberships) {

      my $is_pending_request    = $_->is_pending_request;
      my $is_pending_invitation = $_->is_pending_invitation;
      my $is_active             = $_->is_active;

      next unless $is_active || $is_pending_request || $is_pending_invitation;

      my $member          = $_->user;
      my $group_member_id = $_->group_member_id;
      my $member_id       = $member->user_id;
      my $member_name     = $self->html_encode($member->name);
      my $member_email    = $member->email;
      my $member_level    = $_->level;
      my $row             = {
        'member'            => sprintf('%s%s', $member_name, $is_admin ? " ($member_email)" : ''),
        'level'             => !$is_active ? $is_pending_request ? 'Request recieved' : 'Invitation sent' : ucfirst $member_level
      };
      my @buttons;
      if ($is_admin) {
        if ($is_pending_request) {
          push @buttons,
            $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Allow',      'id' => $group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Allow'}),
            $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Ignore',     'id' => $group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Ignore'}),
            $self->js_link({'href' => {'action' => 'Membership', 'function' => 'BlockUser',  'id' => $group_member_id}, 'inline' => 1, 'target' => 'page', 'caption' => 'Block user from sending further requests'})
          ;
        } else {
          if ($member_level ne 'administrator') { # can not remove an admin
            push @buttons, $self->js_link({
              'href'    => {'action' => 'Membership', 'function' => 'Remove', 'id' => $group_member_id},
              'caption' => $is_pending_invitation ? 'Remove invitation' : 'Remove',
              'confirm' => $is_pending_invitation
                ? "Are you sure you want to deactivate the invitation sent to $member_name ($member_email) for the group $group_name?"
                : "Are you sure you want to remove $member_name ($member_email) from the group $group_name?",
              'target'  => 'page',
              'inline'  => 1,
            });
          }
          push @buttons, $self->js_link({
            'href'    => {'action' => 'Membership', 'function' => 'Change', 'id' => $group_member_id, 'level' => $member_level eq 'administrator' ? 'member' : 'administrator'},
            'caption' => $member_level eq 'administrator' ? 'Demote to member' : 'Make administrator',
            'confirm' => $member_id eq $user->user_id ? q(Are you sure you want to demote yourself to a member? You won't be able to undo this yourself.) : '',
            'target'  => 'none',
            'inline'  => 1,
          }) unless $is_pending_invitation;
        }
      }
      $row->{'buttons'} = join '&nbsp;&middot;&nbsp;', @buttons;
      $table->add_row($row);
    }

    push @sections, $self->js_section({
      'id'          => "group_members_$group_id",
      'subheading'  => 'Members',
      'refresh_url' => $refresh_url,
      'subsections' => [
        $table->render,
        $is_admin
        ? $self->js_link({'href' => {'action' => 'Groups', 'function' => 'Invite', 'id' => $group_id}, 'caption' => 'Invite members', 'class' => 'user-add'})
        : ()
      ]
    });

    return join '', @sections;

  } else {

    my $memberships = $user->active_memberships;

    if (@$memberships) {
  
      # display form to select a group if no group was specified
      return $self->js_section({
        'subsections' => [ $self->select_group_form({
          'memberships' => $memberships,
          'action'      => $hub->url({'action' => 'Groups', 'function' => 'View'}),
          'label'       => 'Select a group to view',
          'submit'      => 'View'
        })->render ]
      });

    # if no group joined
    } else {
      return $self->no_membership_found_page;
    }
  }
}
1;