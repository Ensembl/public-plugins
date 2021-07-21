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

package EnsEMBL::Users::Command::Account::Membership::BlockGroup;

### Block a group from sending further requests to the logged-in user

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Command::Account::Membership);

sub modify_membership {
  my ($self, $membership) = @_;

  if ($membership->is_pending_invitation && $membership->user_id eq $self->hub->user->user_id) {
    $membership->block_group;
    return 1;
  }
  return undef;
}

1;