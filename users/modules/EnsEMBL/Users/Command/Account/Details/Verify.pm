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

package EnsEMBL::Users::Command::Account::Details::Verify;

### Command to active a user login - user lands on this page after clicking on the link sent to him via email for the purpose of verifying his email (when registered via openid)
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_VERIFICATION_FAILED);

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $object  = $self->object;
  my $login   = $object->fetch_login_from_url_code or return $self->redirect_message(MESSAGE_VERIFICATION_FAILED, {'error' => 1});

  $object->activate_user_login($login);
  return $self->redirect_after_login($login->user);
}

1;