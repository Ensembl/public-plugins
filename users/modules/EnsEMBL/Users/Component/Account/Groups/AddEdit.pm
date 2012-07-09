package EnsEMBL::Users::Component::Account::Groups::AddEdit;

### Component to edit group name/details etc
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;
  my $is_add_new  = $hub->function eq 'Add';

  my $membership  = $is_add_new ? $user->create_membership_object : $user->get_membership_object($hub->param('id'));

  if ($membership) {

    my $group       = $membership->group;
    my $level       = $membership->level;
    my $group_types = $object->get_group_types;
    my $notif_types = $object->get_notification_types;

    my $form        = $self->new_form({'action' => $hub->url({qw(action Group function Save)})});

    $form->add_hidden({'name' => 'group_id', 'value'  => $group->group_id});
    if ($level eq 'administrator') {
      $form->add_field({'type'  => 'string',    'name'  => 'name',    'label' => 'Group name',    'value' => $group->name,    'required' => 1 });
      $form->add_field({'type'  => 'text',      'name'  => 'blurb',   'label' => 'Description',   'value' => $group->blurb                    });
      $form->add_field({'type'  => 'dropdown',  'name'  => 'type',    'label' => 'Group type',    'value' => $group->type,    'values' => [ map {'value' => $_, 'caption' => $group_types->{$_}}, sort keys %$group_types  ]});
      $form->add_field({'type'  => 'dropdown',  'name'  => 'status',  'label' => 'Group status',  'value' => $group->status,  'values' => [ map {'value' => $_, 'caption' => ucfirst $_}, qw(active inactive) ]});
    }
    $form->add_field({'type'  => 'yesno',   'value' => $membership->$_ || 0, 'name' => $_, 'label' => $notif_types->{$_}}) for $level eq 'administrator' ? qw(notify_join notify_edit notify_share) : qw(notify_share);
    $form->add_field({'type'  => 'submit',  'value' => $is_add_new ? 'Add' : 'Save'});

    return $self->js_section({'id' => 'add_edit_group', 'subsections' => [ $form->render ]});

  } else {

    # display form to select a group if no group was specified
    return $self->js_section({
      'subsections' => [ $self->select_group_form({
        'memberships' => (my $memberships = $user->active_memberships), # wantarray returns list otherwise
        'action'      => $hub->url({'action' => 'Groups', 'function' => 'Edit'}),
        'label'       => 'Select a group to edit',
        'submit'      => 'Edit'
      })->render ]
    });
  }
}

1;