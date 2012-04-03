package EnsEMBL::ORM::Rose::Manager::User;

### NAME: EnsEMBL::ORM::Rose::Manager::User
### Module to handle multiple User entries 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::User objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

use EnsEMBL::ORM::Rose::Object::User;

sub object_class { 'EnsEMBL::ORM::Rose::Object::User' }

sub get_by_id {
  ## Gets user by id
  ## @param String id
  ## @return User object
  my ($class, $id) = @_;
  
  return $id ? $class->fetch_by_primary_key($id) : undef;
}

sub get_by_email {
  ## Gets user by email
  ## @param String email
  ## @return User object
  my ($class, $email) = @_;

  return shift @{$email ? $class->get_objects('query' => [ 'email', $email ]) : []};
}

1;