=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Command::Account::User::Add;

### Command module to add a user and a local login object to the database after successful local registration
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_EMAIL_INVALID MESSAGE_NAME_MISSING MESSAGE_ALREADY_REGISTERED);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;

  # validation
  my $fields  = $self->validate_fields({ map {$_ => $hub->param($_) || ''} qw(email name) });
  return $self->redirect_register($fields->{'invalid'} eq 'email' ? MESSAGE_EMAIL_INVALID : MESSAGE_NAME_MISSING, { map {$_ => $hub->param($_) || ''} qw(email name organisation country) }) if $fields->{'invalid'};

  my $email   = $fields->{'email'};
  my $login   = $object->fetch_login_account($email);
  return $self->redirect_login(MESSAGE_ALREADY_REGISTERED, {'email' => $email}) if $login && $login->status eq 'active';

  $login    ||= $object->new_login_account({
    'type'          => 'local',
    'identity'      => $email,
    'email'         => $email,
    'status'        => 'pending',
  });

  # update the details provided in the registration form
  $login->name($fields->{'name'});
  $login->$_($hub->param($_) || '') for qw(organisation country);
  $login->subscription([ $hub->param('subscription') ]);

  return $self->handle_registration($login, $email);
}

1;
