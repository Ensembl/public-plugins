package EnsEMBL::Users::Component::Account::Groups::AddEdit;

### Component to edit group name/details etc
### This page does not check whether the user has any group membership or not, so that check is applied in Configuration::Account
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_INACTIVE);

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;
  my $is_add_new  = $hub->function eq 'Add';
  my $membership  = $is_add_new ? $user->create_new_membership_with_group : $object->fetch_accessible_membership_for_user($user, $hub->param('id'));

  if ($membership) {

    my $group       = $membership->group;

    # dont allow editing an inactive group
    return $self->render_message(MESSAGE_GROUP_INACTIVE, {'error' => 1}) if !$is_add_new && $group->status eq 'inactive';

    my $level       = $membership->level;
    my $notif_types = $self->get_notification_types;
    my $form        = $self->new_form({'action' => $hub->url({qw(action Group function Save)})});

    $form->add_hidden({'name' => 'id', 'value'  => $group->group_id});
    if ($level eq 'administrator') {
      my $group_types       = $self->get_group_types;
      my $group_type_values = [];
      while (my ($v, $c) = splice @$group_types, 0, 2) {
        push @$group_type_values, {'value' => $v, 'caption' => {'inner_HTML' => sprintf '%s %s', ucfirst $v, $self->helptip($c)}};
      }
      $form->add_field({'type'  => 'string',    'name'  => 'name',    'label' => 'Group name',    'value' => $group->name,    'required' => 1                 });
      $form->add_field({'type'  => 'text',      'name'  => 'blurb',   'label' => 'Description',   'value' => $group->blurb                                    });
      $form->add_field({'type'  => 'radiolist', 'name'  => 'type',    'label' => 'Group type',    'value' => $group->type,    'values' => $group_type_values  });
    }
    $form->add_field({'type'  => 'yesno',   'value' => $membership->$_ || 0, 'name' => $_, 'label' => $notif_types->{$_}, 'is_binary' => 1}) for $level eq 'administrator' ? qw(notify_join notify_edit notify_share) : qw(notify_share);
    $form->add_field({'type'  => 'submit',  'value' => $is_add_new ? 'Add' : 'Save'});

    return $self->js_section({'id' => 'add_edit_group', 'subsections' => [ $form->render ]});

  } else {

    my $memberships = $user->active_memberships;

    # display form to select a group if no group was specified
    return $self->js_section({
      'heading'     => 'Edit group',
      'subsections' => [ $self->select_group_form({
        'memberships' => $memberships,
        'action'      => $hub->url({'action' => 'Groups', 'function' => 'Edit'}),
        'label'       => 'Select a group to edit',
        'submit'      => 'Edit'
      })->render ]
    });
  }
}

1;