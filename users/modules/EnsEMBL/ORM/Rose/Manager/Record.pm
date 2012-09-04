package EnsEMBL::ORM::Rose::Manager::Record;

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Record;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class      { 'EnsEMBL::ORM::Rose::Object::Record'      }
sub get_user_records  { return shift->_get_records('user', @_);   } ## Wrapper around get_objects method to filter records by record type user  ## @params As accepted by get_objects
sub get_group_records { return shift->_get_records('group', @_);  } ## Wrapper around get_objects method to filter records by record type group ## @params As accepted by get_objects

sub _get_records {
  ## @private
  my ($self, $type, %params) = @_;

  push @{$params{'query'} ||= []}, 'record_type', $type;
  return $self->get_objects(%params);
}

1;
