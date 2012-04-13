package EnsEMBL::ORM::Rose::Object::Login;

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object);

use EnsEMBL::Web::Tools::RandomString qw(random_string);

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
    email           => {'column' => 'data'},
    name            => {'column' => 'data'},
    organisation    => {'column' => 'data'},
    country         => {'column' => 'data'},
  ],

  relationships   => [
    user            => {
      'type'          => 'many to one',
      'class'         => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'    => {'user_id' => 'user_id'},
    }
  ]
);

sub reset_salt {
  ## Resets the random key salt
  shift->salt(random_string(8));
}

sub activate {
  ## Adds the information about user name, organisation, country it to the related user object (does not save to the database afterwards)
  my $self = shift;
  my $user = $self->user;
  $user->$_ or $self->$_ and $user->$_($self->$_) for qw(name organisation country);
  $self->status('active');
}

1;