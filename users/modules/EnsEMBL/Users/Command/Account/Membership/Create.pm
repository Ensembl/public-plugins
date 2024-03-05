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

package EnsEMBL::Users::Command::Account::Membership::Create;

### Creates the membership object for an invitation sent to a new user (saved in user records)
### Membership created is a "pending" invitation

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND MESSAGE_URL_EXPIRED);

use parent qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  my %redirect_url  = qw(type Account action Groups);
  my $invitation    = $self->object->fetch_invitation_record_from_url_code;

  if ($invitation) {

    # we do not check if the email to which the invitation was sent is same as user's email as user can have a different registered email
    my $group = $invitation->group;
    if ($group && $group->status eq 'active') {
      my $group_id = $group->group_id;
      $membership->group_id($group_id);
      $membership->make_invitation;
      $membership->save('user' => $invitation->created_by_user);
      $invitation->delete;
    } else {
      $redirect_url{'err'} = MESSAGE_GROUP_NOT_FOUND;
    }
  } else {
    $redirect_url{'err'} = MESSAGE_URL_EXPIRED;
  }
  $self->redirect_url(\%redirect_url);
  return undef; # return undef so the parent class doesn't save the membership object again
}

1;