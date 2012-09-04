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

  return $self->handle_registration($login, $email);
}

1;
