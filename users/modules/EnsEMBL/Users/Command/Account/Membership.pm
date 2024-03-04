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

package EnsEMBL::Users::Command::Account::Membership;

### Allows the user to accept or decline a membership invitation, or allows the admin user to allow or ignore a membership request from a user

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $r_user      = $hub->user->rose_object;
  my $membership  = $hub->function ne 'Create'
    ? $hub->param('id')
    ? $object->fetch_membership($hub->param('id'), {'with_objects' => 'group', 'query' => ['group.status' => 'active']})
    : undef
    : $r_user->create_membership_object
  or return $self->redirect_message(MESSAGE_GROUP_NOT_FOUND, {'error' => 1, 'back' => $self->redirect_url});

  if ($self->modify_membership($membership)) {
    $membership->save('user' => $r_user);
    $hub->user->has_changes(1);
  }

  return $self->ajax_redirect($self->redirect_url);
}

sub redirect_url {
  my $self  = shift;
  my $hub   = $self->hub;
  $self->{'_redirect_url'} = shift if @_;
  return $self->{'_redirect_url'} ? $hub->url($self->{'_redirect_url'}) : $hub->PREFERENCES_PAGE;
}

sub modify_membership {} # implemented in child classes

1;