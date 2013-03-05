package EnsEMBL::Users::Component::Account::Groups::Invite;

### Form to invite user to a group
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;
  my $group_id    = $hub->param('id');
  my $adminship   = $group_id ? $object->fetch_active_membership_for_user($user, $group_id, {'query' => ['level' => 'administrator']}) : undef;
  my $adminships  = $adminship ? [] : $user->admin_memberships; # if membership not found (or group id not specified), we display all the groups for the user to select one from.
  my $html        = '';

  if ($group_id && !$adminship) {
    $html .= $self->render_message(MESSAGE_GROUP_NOT_FOUND, {'error' => 1});
  }

  if ($adminship or @$adminships) {

    my $form = $self->new_form({'action' => {qw(action Group function Invite)}, 'csrf_safe' => 1});

    $form->add_notes({
      'text'        => sprintf('To invite new members to join %s group, enter one email address per person. Users not already registered with %s will be asked to do so before accepting your invitation.', $adminship ? 'the' : 'a', $self->site_name)
    });

    if ($adminship) {
      my $group = $adminship->group;
      $form->add_field({
        'label'     => 'Group',
        'type'      => 'noedit',
        'name'      => 'group_id',
        'caption'   => $group->name,
        'value'     => $group->group_id
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
  
    $html .= $self->js_section({
      'heading'     => 'Invite new members',
      'subsections' => [ $form->render ]
    });

  } else {

    $html .= $self->js_section({
      'heading'     => 'Invite new members',
      'subsections' => [
        sprintf '<p>You do not have administration rights for any of the groups to invite any members. You can though %s and then invite members to it.</p>',
        $self->js_link({
          'href'    => {'action' => 'Groups', 'function' => 'Add'},
          'caption' => 'create a new group'
        })
      ]
    });
  }

  return $html;
}

1;
