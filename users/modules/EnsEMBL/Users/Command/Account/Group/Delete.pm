=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Command::Account::Group::Delete;

### Command module to delete a group
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_UNKNOWN_ERROR MESSAGE_GROUP_NOT_FOUND);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $return_url;

  if (my $group_id = $hub->param('id')) {

    if (my $membership = $object->fetch_accessible_membership_for_user($user->rose_object, $group_id, {
      'with_objects'  => ['group', 'group.memberships', 'group.records'],
      'query'         => ['level' => 'administrator']
    })) {

      my $group = $membership->group;

      # do we need to notify anyone?
      my @curious_admins  = map {$_->user_id ne $user->user_id && $_->notify_edit && $_->user || ()} @{$group->admin_memberships};
      my $group_name      = $group->name;

      if ($group->delete('cascade' => 1)) {

        $self->mailer->send_group_deletion_notification_email(\@curious_admins, $group_name);
        $return_url = {'action' => 'Groups', 'function' => ''};

      } else {

        $return_url = {'action' => 'Groups', 'function' => 'View', 'id' => $group_id, 'err' => MESSAGE_UNKNOWN_ERROR};
      }
    }
  }

  return $self->ajax_redirect($hub->url($return_url || {'action' => 'Groups', 'function' => '', 'err' => MESSAGE_GROUP_NOT_FOUND}));
}

1;
