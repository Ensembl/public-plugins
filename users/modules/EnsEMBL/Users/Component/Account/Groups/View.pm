package EnsEMBL::Users::Component::Account::Groups::View;

### Page for a logged in user to view details of one of his joined/owned groups
### This page does not check whether the user has any group membership or not, so that check is applied in Configuration::Account
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
    my $is_active   = $group->status eq 'active';
    my $notif_types = $self->get_notification_types;

    my @sections;

    # group details section
    push @sections, $self->js_section({
      'heading'       => "Group: $group_name",
      'heading_links' => [$is_active ? {
        'href'          => {'action' => 'Groups', 'function' => 'Edit', 'id' => $group_id},
        'title'         => 'Edit settings',
        'sprite'        => 'edit_icon',
      } : (), $is_admin ? {
        'href'          => {'action' => 'Groups', 'function' => 'ConfirmDelete', 'id' => $group_id},
        'title'         => 'Delete group',
        'sprite'        => 'delete_icon'
      } : {
        'href'          => {'action' => 'Membership', 'function' => 'Unjoin', 'id' => $membership->group_member_id, 'csrf_safe' => 1},
        'title'         => 'Unsubscribe',
        'sprite'        => 'stop_icon',
        'confirm'       => "You are about to remove yourself from the group &quot;$group_name&quot;. This action can not be undone."
      }],
      'subsections'   => [
        $group->status eq 'active' ? () : sprintf(q(<p class="italic">This group has been set inactive, ie. it's not visible to any member. %s to make it active now.</p>), $self->js_link({
          'href'        => {'action' => 'Group', 'function' => 'Save', 'status' => 'active', 'id' => $group_id, 'csrf_safe' => 1},
          'caption'     => 'Click here',
        })),
        $self->two_column([
          'Group name'  => $group_name,
          'Description' => $self->html_encode($group->blurb),
          'Type'        => sprintf('%s - %s', ucfirst $group->type, {@{$self->get_group_types}}->{$group->type} || ''),
          $is_active ? (
          '<b>Notification settings</b>', '',
          map { $notif_types->{$_} => $membership->$_ ? 'Yes' : 'No' } $is_admin ? qw(notify_join notify_edit notify_share) : qw(notify_share)
          ) : ()
        ])
      ]
    });

    # only show this section if group is active
    if ($is_active) {

      # bookmarks section
      my $bookmarks = $group->bookmarks;

      push @sections, $self->js_section({
        'subheading'        => 'Bookmarks',
        'subheading_links'  => [ {'href' => {'action' => 'Share', 'function' => 'Bookmark', 'group' => $group_id}, 'title' => 'Share from my bookmarks', 'sprite' => 'bookmark_icon'} ],
        'subsections'       => [ @$bookmarks ? $self->bookmarks_table({'bookmarks' => $bookmarks, 'group' => $group}) : q(<p>There is no bookmark shared with the group.</p>) ]
      });

      # members
      $group->load('with' => [ 'memberships', 'memberships.user' ]);
      my @memberships = grep {$_->user} @{$group->memberships};

      my $table = $self->new_table([
        {'key' => 'member',   'title' => 'Member',  'width' => '30%'                    },
        {'key' => 'level',    'title' => 'Level',   'width' => $is_admin ? '20%' : '70%'},
        $is_admin ?
        {'key' => 'buttons',  'title' => '',        'width' => '50%'                    } : ()
      ], [], {'class' => 'tint', 'data_table' => 'no_col_toggle', 'exportable' => 0, 'data_table_config' => {'iDisplayLength' => 25}});

      for (sort {$a->user->name cmp $b->user->name} @memberships) {

        my $is_pending_request    = $_->is_pending_request;
        my $is_pending_invitation = $_->is_pending_invitation;
        my $is_active             = $_->is_active;

        next unless $is_active || ($is_admin && ($is_pending_request || $is_pending_invitation));

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
              $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Allow',      'id' => $group_member_id, 'csrf_safe' => 1}, 'caption' => 'Allow'}),
              $self->js_link({'href' => {'action' => 'Membership', 'function' => 'Ignore',     'id' => $group_member_id, 'csrf_safe' => 1}, 'caption' => 'Ignore'}),
              $self->js_link({'href' => {'action' => 'Membership', 'function' => 'BlockUser',  'id' => $group_member_id, 'csrf_safe' => 1}, 'caption' => 'Block user from sending further requests'})
            ;
          } else {
            if ($member_level ne 'administrator') { # can not remove an admin
              push @buttons, $self->js_link({
                'href'    => {'action' => 'Membership', 'function' => 'Remove', 'id' => $group_member_id, 'csrf_safe' => 1},
                'caption' => $is_pending_invitation ? 'Remove invitation' : 'Remove',
                'confirm' => $is_pending_invitation
                  ? "Are you sure you want to remove the invitation sent to $member_name ($member_email) for the group $group_name?"
                  : "Are you sure you want to remove $member_name ($member_email) from the group $group_name?"
              });
            }
            push @buttons, $self->js_link({
              'href'    => {'action' => 'Membership', 'function' => 'Change', 'id' => $group_member_id, 'csrf_safe' => 1, 'level' => $member_level eq 'administrator' ? 'member' : 'administrator'},
              'caption' => $member_level eq 'administrator' ? 'Demote to member' : 'Make administrator',
              'confirm' => $member_id eq $user->user_id ? q(Are you sure you want to demote yourself to a member? You won't be able to undo this yourself.) : ''
            }) unless $is_pending_invitation;
          }
        }
        $row->{'buttons'} = join '&nbsp;&middot;&nbsp;', @buttons;
        $table->add_row($row);
      }

      push @sections, $self->js_section({
        'subheading'        => 'Members',
        'subheading_links'  => [ $is_admin ? {'href' => {'action' => 'Groups', 'function' => 'Invite', 'id' => $group_id}, 'title' => 'Invite new members', 'sprite' => 'user-add-icon'} : () ],
        'subsections'       => [ $table->render ]
      });
    }

    return join '', @sections;

  } else {

    my $memberships = $user->accessible_memberships; # accessible_memberships not active_membership as you can also view an inactive group if you are an admin of that group

    # display form to select a group if no group was specified
    return $self->js_section({
      'heading'     => 'View group',
      'subsections' => [ @$memberships ? $self->select_group_form({
        'memberships' => $memberships,
        'action'      => {'action' => 'Groups', 'function' => 'View'},
        'label'       => 'Select a group to view',
        'submit'      => 'View'
      })->render : $self->no_group_message ]
    });
  }
}

1;