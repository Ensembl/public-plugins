=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Users::Component::Account::Groups::Invite;

### Form to invite user to a group

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;
  my $group_id    = $hub->param('id');
  my $admin_group = $group_id ? $object->fetch_active_group_for_user($user, $group_id, {'query' => ['level' => 'administrator']}) : undef;
  my $adminships  = $admin_group ? [] : $user->admin_memberships; # if membership not found (or group id not specified), we display all the groups for the user to select one from.
  my $html        = '';

  if ($group_id && !$admin_group) {
    $html .= $self->render_message(MESSAGE_GROUP_NOT_FOUND, {'error' => 1});
  }

  if ($admin_group or @$adminships) {

    my $form = $self->new_form({'action' => {qw(action Group function Invite)}, 'csrf_safe' => 1});

    $form->add_notes({
      'text'        => sprintf('To invite new members to join %s group, enter one email address per person. Users not already registered with %s will be asked to do so before accepting your invitation.', $admin_group ? 'the' : 'a', $self->site_name)
    });

    if ($admin_group) {
      $form->add_field({
        'label'     => 'Group',
        'type'      => 'noedit',
        'name'      => 'group_id',
        'caption'   => $admin_group->name,
        'value'     => $admin_group->group_id
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
