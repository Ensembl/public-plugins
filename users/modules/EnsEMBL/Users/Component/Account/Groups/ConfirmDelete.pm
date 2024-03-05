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

package EnsEMBL::Users::Component::Account::Groups::ConfirmDelete;

### Page to confirm if the user wants to delete a group
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use parent qw(EnsEMBL::Users::Component::Account);

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
        'class'       => 'buttons-inline',
        'heading'     => "Delete group $group_name",
        'subsections' => [
          $message,
          $self->js_link({
            'href'        => {'action' => 'Groups', 'function' => 'View', 'id' => $group_id},
            'caption'     => 'Cancel',
            'class'       => 'arrow-left',
            'button'      => 1
          }), $is_active ? (
          $self->js_link({
            'href'        => {'action' => 'Group', 'function' => 'Save', 'status' => 'inactive', 'id' => $group_id, 'csrf_safe' => 1},
            'caption'     => 'Inactivate',
            'class'       => 'user-group-inactivate',
            'button'      => 1
          })) : (),
          $self->js_link({
            'href'        => {'action' => 'Group', 'function' => 'Delete', 'id' => $group_id, 'csrf_safe' => 1},
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
