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

package EnsEMBL::Users::Command::Account::Group::Join;

### Command module to enable user to join (or send request to) a group
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self      = shift;
  my $object    = $self->object;
  my $hub       = $self->hub;
  my $r_user    = $hub->user->rose_object;

  if (my $group = $object->fetch_group($hub->param('id'))) {

    my $group_type = $group->type;
    if ($group_type ne 'private') {
      my $membership = $group->membership($r_user);
      my $action;

      if ($membership->is_user_blocked || $membership->is_active) { # if membership is active, or the user is blocked by the group admin, redirect user to the preferences page
        return $self->ajax_redirect($hub->PREFERENCES_PAGE);

      } elsif ($membership->is_pending_invitation || $group_type eq 'open') {
        $membership->activate;

      } else {
        $membership->make_request;
      }

      # notify admins
      $self->send_group_joining_notification_email($group, $membership->is_active);

      $membership->save('user' => $r_user);
      return $self->ajax_redirect($group_type eq 'open' ? $hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id}) : $hub->PREFERENCES_PAGE);
    }
  }

  return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'List', 'err' => MESSAGE_GROUP_NOT_FOUND}));
}

1;
