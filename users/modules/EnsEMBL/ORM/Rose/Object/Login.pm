package EnsEMBL::ORM::Rose::Object::Login;

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use EnsEMBL::Web::Tools::RandomString qw(random_string);
use EnsEMBL::Web::Tools::Encryption qw(encrypt_password);

use constant ROSE_DB_NAME => 'user';

__PACKAGE__->meta->setup(
  table           => 'login',

  columns         => [
    login_id        => {'type' => 'serial', 'primary_key' => 1, 'not_null' => 1},
    user_id         => {'type' => 'int', 'length'  => '11'},
    identity        => {'type' => 'varchar', 'length' => '255', 'not_null' => 1},
    type            => {'type' => 'enum', 'values' => [qw(local openid ldap)], 'not_null' => 1, 'default' => 'local'},
    data            => {'type' => 'datamap', 'length' => '1024'},
    status          => {'type' => 'enum', 'values' => [qw(active pending)], 'not_null' => 1, 'default' => 'pending'},
    salt            => {'type' => 'varchar', 'length' => '8'},
  ],

  virtual_columns => [
    provider        => {'column' => 'data'},
    password        => {'column' => 'data'},
    ldap_user       => {'column' => 'data'},
    email           => {'column' => 'data'},
    name            => {'column' => 'data'},
    organisation    => {'column' => 'data'},
    country         => {'column' => 'data'},
    subscription    => {'column' => 'data'}
  ],

  relationships   => [
    user            => {
      'type'          => 'many to one',
      'class'         => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'    => {'user_id' => 'user_id'},
    }
  ]
);

sub get_url_code {
  ## Creates a url code for a given login
  ## @return String
  my $self = shift;
  my $user = $self->user;

  return sprintf('%s-%s-%s', $user ? $user->user_id : '0', $self->login_id, $self->salt);
}

sub has_trusted_provider {
  ## In case of an openid login, tells whether the provider is trusted or not.
  ## @return 1 if trusted openid provider, 0 if not trusted or if login is not of type openid
  my $self = shift;

  return $self->type eq 'openid' ? {@{$SiteDefs::OPENID_PROVIDERS}}->{$self->provider}->{'trusted'} : 0;
}

sub reset_salt {
  ## Resets the random key salt
  shift->salt(random_string(8));
}

sub reset_salt_and_save {
  ## Resets the salt before saving the object - use this instead of regular save method unless reseting the salt is not needed
  ## @params As requried by save method
  my $self = shift;
  $self->reset_salt;
  return $self->save(@_);
}

sub set_password {
  ## Encrypts the password before saving it to the object
  ## @param Unencrypted password string
  my ($self, $password) = @_;
  $self->password(encrypt_password($password));
}

sub verify_password {
  ## Checks a plain text password against an encrypted password
  ## @param Password string
  ## @return Boolean accordingly
  my ($self, $password) = @_;
  return encrypt_password($password) eq $self->password;
}

sub activate {
  ## Activates the login object after copying the information about user name, organisation, country it to the related user object (does not save to the database afterwards)
  ## @param User object (if not already linked to the login)
  my ($self, $user) = @_;
  if ($user) {
    $user->add_logins([ $self ]);
  } else {
    $user = $self->user;
  }
  $self->$_ and !$user->$_ and $user->$_($self->$_) for qw(name organisation country);

  $self->reset_salt;
  $self->status('active');
}

1;