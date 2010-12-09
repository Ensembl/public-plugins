package EnsEMBL::Admin::Data::Rose::Session;

### NAME: EnsEMBL::Admin::Data::Rose::Session;
### Wrapper for one or more EnsEMBL::Admin::Rose::Object::Session objects

### STATUS: Under Development

### DESCRIPTION:

use strict;

use EnsEMBL::Admin::Rose::Manager::Session;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_primary_keys {
  ## @overrides
  ## sets primary key for the object as in the database table
  ## called by Rose->_init
  my $self = shift;
  $self->{'_primary_keys'} = [qw(session_id)];
}

sub set_classes {
  ## links the corresponding Rose Object and Rose Object Manager classes
  ## called by Rose->_init
  ## @overrides
  my $self = shift;
  $self->{'_object_class'} = 'EnsEMBL::Admin::Rose::Object::Session';
  $self->{'_manager_class'} = 'EnsEMBL::Admin::Rose::Manager::Session';
}

### Following methods help for data mining for fetching data (each with different criteria) from the db table

sub fetch_all {
  ## fetches all sessions from the db for the given release
  ## @return ArrayRef of EnsEMBL::Admin::Rose::Object::Session objects if found any
  my ($self, $release) = @_;
  return undef unless $release;
  
  my $objects = $self->manager_class->get_sessions(
    query   => [
      db_release => $release,
    ],
    sort_by => 'session_id',
  );
  return $objects;
}

sub fetch_first {
  ## fetches first session from the db for the given release
  ## @return ArrayRef of EnsEMBL::Admin::Rose::Object::Session objects if found any
  my ($self, $release) = @_;
  return undef unless $release;

  my $objects = $self->manager_class->get_sessions(
    query   => [
      db_release => $release,
    ],
    sort_by => 'session_id ASC',
    limit   => 1
  );
  return $objects->[0];
}

sub fetch_last {
  ## fetches last session from the db for the given release
  ## @return ArrayRef of EnsEMBL::Admin::Rose::Object::Session objects if found any
  my ($self, $release) = @_;
  return undef unless $release;

  my $objects = $self->manager_class->get_sessions(
    query   => [
      db_release => $release,
    ],
    sort_by => 'session_id DESC',
    limit   => 1
  );
  return $objects->[0];
}

1;