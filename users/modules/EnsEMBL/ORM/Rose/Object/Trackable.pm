package EnsEMBL::ORM::Rose::Object::Trackable;

### NAME: EnsEMBL::ORM::Rose::Object::Trackable

### DESCRIPTION: ORM parent class for any table that contains columns 'created_by','modified_by' (both user_id foreign keys), 'created_at' and 'modified_at'

use strict;
use warnings;

use Rose::DateTime::Util qw(parse_date);
use EnsEMBL::ORM::Rose::MetaData::Trackable;

use base qw(EnsEMBL::ORM::Rose::Object);

sub meta_class {
  return 'EnsEMBL::ORM::Rose::MetaData::Trackable';
}

sub save {
  ## @overrides
  ## Adds the trackable info to the record before saving it, iff user provided in the hash argument
  ## @params Hash with an extra key 'user' containing current user (Rose object) along with keys as accepted by Rose::DB::Object->save
  my ($self, %params) = @_;

  my $user  = delete $params{'user'};
  my $key   = $self->get_primary_key_value ? 'modified' : 'created';
  my $by    = "${key}_by";
  my $at    = "${key}_at";

  $self->$by($user->user_id) if $user;
  $self->$at(parse_date('now'));

  return $self->SUPER::save(%params);
}

sub clone_and_reset {
  ## @overrides
  ## Resets the values in the trackable columns along with other unique keys and primary keys
  ## @return Cloned trackable rose object
  my $self  = shift;
  my $clone = $self->SUPER::clone_and_reset(@_);
  $clone->$_(undef) for qw(created_by created_at modified_by modified_at);
  return $clone;
}

1;