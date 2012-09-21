package EnsEMBL::Users::Component::Account::Groups::ConfirmDelete;

### Page to confirm if the user wants to delete a group
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $user        = $hub->user->rose_object;
  my $group_id    = $hub->param('id');
  my $membership  = $object->fetch_accessible_membership_for_user($user, $group_id, {'with_objects' => ['group']});

  if ($membership) {

    my $group       = $membership->group;
    my $group_name  = $self->html_encode($group->name);

    if ($membership->level eq 'administrator') {

      my $is_active = $group->status eq 'active';
      my $message   = qq(<p>You are about to delete the group <b>$group_name</b> permanently. This action can not be undone.) . ( $is_active
        ? q(Alternatively, you can choose to <i>inactivate</i> the group in which case it will not be accessible to any member, but you can reactivate the group in future.</p>)
        : q()
      );

      return $self->js_section({
        'id'          => 'confirm_delete',
        'class'       => 'buttons-inline',
        'heading'     => "Delete group $group_name",
        'subsections' => [
          $message,
          $self->js_link({
            'href'        => {'action' => 'Groups', 'function' => 'View', 'id' => $group_id},
            'caption'     => 'Cancel',
            'class'       => 'arrow-left',
            'cancel'      => 1, # TODO
            'button'      => 1
          }), $is_active ? (
          $self->js_link({
            'href'        => {'action' => 'Group', 'function' => 'Save', 'status' => 'inactive', 'id' => $group_id},
            'caption'     => 'Inactivate',
            'class'       => 'user-group-inactivate',
            'button'      => 1
          })) : (),
          $self->js_link({
            'href'        => {'action' => 'Group', 'function' => 'Delete', 'id' => $group_id},
            'caption'     => 'Delete',
            'class'       => 'user-group-delete',
            'button'      => 1
          })
        ]
      });
    }
  }

  return $self->render_message(MESSAGE_GROUP_NOT_FOUND, {'error' => 1});
}

1;
