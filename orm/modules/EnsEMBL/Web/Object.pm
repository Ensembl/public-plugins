=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object;

## Plugin to EnsEMBL::Web::Object for the ORM specific Web::Object
## Handles multiple ORM::EnsEMBL::Rose::Object objects

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

sub rose_objects {
  ## Getter/Setter for the rose objects
  ## Basically this method takes the data across from Web::Object to the Web::Component, to keep 'business logic' away from Components
  ## Saves and returns Rose::Object drived objects
  ## @param Key name for saving the objects (optional) - defaults to saving as (or retrieving from) primary rose objects
  ## @param Rose::Object drived object (if adding new object) - ArrayRef of Rose::Object drived objects, in case of multiple objects
  ## @return ArrayRef of the saved rose objects or undef if nothing saved
  ## @example $object->rose_objects('users', \@users);  #saves under 'users' key
  ## @example $object->rose_objects('users', $user);    #saves under 'users' key an array with first element as $user
  ## @example $object->rose_objects(\@rose_objects);    #saves as primary rose objects
  ## @example $object->rose_objects($rose_object);      #saves as primary rose object
  ## @example $object->rose_objects('users');           #returns the arrayref saved at 'users' key
  ## @example $object->rose_objects;                    #returns arrayref of primary rose objects
  my $self = shift;
  my $type = shift || '0';
  my $objs = shift;
  
  $type and ref $type and $objs = $type and $type = '0';

  $self->{'_rose_objects'} ||= {};

  if ($objs) {
    $objs = [ $objs ] unless ref $objs eq 'ARRAY';
    $self->{'_rose_objects'}{$type} = $objs;
  }

  return $self->{'_rose_objects'}{$type};
}

sub rose_object {
  ## Gets the first primary rose object saved inside this object
  my $rose_objects = shift->rose_objects;

  return $rose_objects && @$rose_objects ? $rose_objects->[0] : undef;
}

sub create_empty_object {
  ## Wrapper around the default manager's create_empty_object method
  ## @param Object type 
  return shift->rose_manager(@_)->create_empty_object;
}

sub rose_errors {
  ## Gets all the errors thrown by Rose api
  ## @param Flag telling whether to return the errors as thrown by rose, or format them to a readable form - returns formatted error by default
  ## @return ArrayRef of strings
  my ($self, $raw) = @_;
  my $errors = $self->deepcopy($self->{'_rose_error'} ||= []);
  if (!$raw) {
    for (0..scalar @$errors - 1) {
      if ($errors->[$_] =~ /(Duplicate\sentry\s\'[^\']*\')/) {
        $errors->[$_] = $1;
      }
      ## TODO - format other errors
    }
  }
  return $errors;
}

sub rose_error {
  ## Gets the last error thrown by Rose api while executing an sql query
  ## @param Flas as in function rose_errors
  return shift->rose_errors(@_)->[-1];  
}

sub save {
  ## Wrapper to Rose::DB::Object's save method to handle multiple objects with web-friendly error-handling
  ## If any error occours while saving, it can be accessed with object->rose_errors
  ## @param Key for the rose objects - optional - defaults to the primary rose objects
  ## @param Hashref of the hash to be passed to rose object's save method as arg
  ## @return ArrayRef of successfully saved rose objects
  my ($self, $type, $params) = @_;
  
  $type and ref $type eq 'HASH' and $params = $type and $type = '0';

  my $objs = [];
  
  ## reset errors
  $self->{'_rose_error'} = [];
  
  $params ||= {};
  $params->{'changes_only'} = 1;

  my %user = ('user' => delete $params->{'user'} || $self->hub->user->rose_object);

  for (@{$self->rose_objects($type || '0')}) {

    my $obj;

    try {
      $obj = $_->save(%$params, $_->meta->trackable ? %user : ());
      push @$objs, $_;
    } catch {};

    if (!$obj) {
      push @{$self->{'_rose_error'}}, $_->error;
    }
  }

  return $objs;
}

sub delete {
  ## Deletes the data from the database
  ## @param Key for the rose objects - optional - defaults to the primary rose objects
  ## @return ArrayRef of flags corresponding to each rose objects
  my ($self, $type) = @_;

  my $flags = [];

  ## reset errors
  $self->{'_rose_error'} = [];


  for (@{$self->rose_objects($type || '0')}) {

    if ($_->delete('cascade' => 0)) {
      warn sprintf('Delete log: %s removed %s (%s) %s', $self->hub->user->email, ref $_, $_->get_title, "\n");  # this is the only way to trace who removed the data
      push @$flags, 1;
    }
    else {
      push @{$self->{'_rose_error'}}, $_->error;
    }
  }
  return $flags;
}

sub retire {
  ## Alternative 'delete' - sets 'inactive_flag_column' to 'inactive_flag_value'
  ## @param Key for the rose objects - optional - defaults to the primary rose objects
  ## @return ArrayRef of successfully retired rose objects
  my ($self, $type) = @_;
  
  my $objs = [];

  ## reset errors
  $self->{'_rose_error'} = [];

  my %user = ('user' => $self->hub->user);

  for (@{$self->rose_objects($type || '0')}) {
    my $meta    = $_->meta;
    my $column  = $meta->inactive_flag_column;
    my $value   = $meta->inactive_flag_value;

    unless ($column) {
      my $rose_object_type = ref $_;
      warn sprintf('Could not retire object of type %s. Either specify an "inactive_column" in %1$s->meta->setup() or return '.
        '"delete" from %s->permit_delete() so that it can be deleted from the database permanently.', $rose_object_type, ref $self);
      push @{$self->{'_rose_error'}}, sprintf('Could not inactivate %s (%s)', $rose_object_type =~ /([^\:]+)$/, $_->get_primary_key_value);
      next;
    }

    $_->$column($value);
    if (my $obj = $_->save('changes_only' => 1, $meta->trackable ? %user : ())) {
      push @$objs, $obj;
    }
    else {
      push @{$self->{'_rose_error'}}, $_->error;
    }
  }
  return $objs;
}

1;
