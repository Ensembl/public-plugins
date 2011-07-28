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
  my ($self, $id) = @_;
  
  return $id ? $self->fetch_by_primary_key($id) : undef;
}

sub get_by_email {
  ## Gets user by email
  ## @param String email
  ## @return ArrayRef of User objects, undef if any error
  my ($self, $email) = @_;

  return $email ? $self->get_objects('query' => [ 'email', $email ]) : undef;
}
1;