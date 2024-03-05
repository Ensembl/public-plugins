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

package EnsEMBL::Users::Command::Account::Details::RemoveLogin;

### Command module to remove a login object linked to the user
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_CANT_DELETE_LOGIN);

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $hub     = $self->hub;
  my $user    = $hub->user;

  my $logins  = { map {$_->login_id => $_} @{$user->rose_object->logins} };
  my $login   = delete $logins->{$hub->param('id') || 0};

  if ($login) {

    # can not delete the only login account attached to the user, or any login of type other than openid or local
    return $self->redirect_message(MESSAGE_CANT_DELETE_LOGIN) unless keys %$logins && $login->type =~ /^(openid|local)$/;

    $login->delete;
  }

  return $self->ajax_redirect($hub->PREFERENCES_PAGE);
}

1;