package EnsEMBL::ORM::Rose::Manager::Trackable;

### NAME: EnsEMBL::ORM::Rose::Manager::Trackable

### DESCRIPTION:
### Parent manager class for managers for trackable obects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub fetch_all_created_by {
  ## Fetches all records created by a given user
  ## @param User id (integer)
  ## @param (Optional) Extra bits to be a part of the query (HashRef with keys as supported by manager->get_objects)
  ## @return ArrayRef of Rose::Object drived classes, undef if any error
  return shift->_fetch_all_by('created', @_);
}

sub fetch_all_modified_by {
  ## Fetches all records modified by a given user
  ## @param User id (integer)
  ## @param (Optional) Extra bits to be a part of the query (HashRef with keys as supported by manager->get_objects)
  ## @return ArrayRef of Rose::Object drived classes, undef if any error
  return shift->_fetch_all_by('modified', @_);
}

sub fetch_all_created_after   {} ## TODO
sub fetch_all_modified_after  {} ## TODO
sub fetch_all_created_before  {} ## TODO
sub fetch_all_modified_before {} ## TODO

sub _fetch_all_by {
  ## Private helper method to support fetch_all_created_by & fetch_all_modified_by
  my ($self, $type, $user_id, $params) = @_;

  return unless $user_id;

  $params             ||= {};
  $params->{'query'}  ||= [];
  push @{$params->{'query'}}, ("${type}_by", $user_id);
  
  return $self->get_objects(%$params);
}

1;