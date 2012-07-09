package EnsEMBL::Users::Component::Account::Groups::Invite;

### Form to invite user to a group
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;
  my $adminship   = $hub->param('id') ? $user->get_membership_object($hub->param('id'), 'administrator') : undef;
  my $adminships  = $adminship ? [] : $user->admin_memberships; # if membership not found (or group id not specified), we display all the groups for the user to select one from.

  if ($adminship or @$adminships) {

    my $form = $self->new_form({'action' => $hub->url({'action' => 'Group', 'function' => 'Invite'})});
  
    $form->add_notes({
      'text'        => sprintf('To invite new members to join %s group, enter one email address per person. Users not already registered with %s will be asked to do so before accepting your invitation.', $adminship ? 'the' : 'a', $self->site_name)
    });
    if ($adminship) {
      $form->add_field({
        'label'     => 'Group',
        'type'      => 'noedit',
        'name'      => 'group_id',
        map {(
          'caption' => $_->name,
          'value'   => $_->group_id
        )} $adminship->group
      });

    } else {
      $form->add_field({
        'type'      => 'dropdown',
        'name'      => 'group_id',
        'label'     => 'Group',
        'values'    => [ map {$_ = $_->group; {'caption' => $_->name, 'value' => $_->group_id}} @$adminships ]
      });
    }
    $form->add_field({
      'type'        => 'text',
      'name'        => 'emails',
      'label'       => 'Email addresses',
      'required'    => 1,
      'value'       => $hub->param('emails') || '',
      'notes'       => 'Multiple email addresses should be separated by commas.'
    });
    $form->add_field({
      'type'        => 'submit',
      'value'       => 'Send'
    });
  
    return $self->js_section({
      'id'          => 'invite_members',
      'heading'     => 'Invite new members',
      'subsections' => [ $form->render ]
    });

  } else {

    return $self->js_section({
      'id'          => 'invite_members',
      'heading'     => 'Invite new members',
      'subsections' => [
        '<p>You do not have administration rights for any of the group to invite any members. You can though create a new group and then add members to it.</p>',
        $self->link_create_new_group
      ]
    });
  }
}

1;