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

package EnsEMBL::Users::Command::Account::Membership::Change;

### Changes the level of a user's membership

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_CANT_DEMOTE_ADMIN);

use parent qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;
  my $hub   = $self->hub;
  my $group = $membership->group;
  my $admin = $hub->user->rose_object;
  my $url   = {'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id};

  if ($admin->is_admin_of($group)) {
    if ($membership->user_id eq $admin->user_id && scalar @{$group->admin_memberships} == 1) { # the only admin of the group can't demote himself
      $self->redirect_url({
        'action'  => 'Message',
        'err'     => MESSAGE_CANT_DEMOTE_ADMIN,
        'back'    => $hub->url($url)
      });
    } else {
      $membership->level($hub->param('level') eq 'administrator' ? 'administrator' : 'member');
      $self->redirect_url($url);
      return 1;
    }
  }
  return undef;
}

1;
