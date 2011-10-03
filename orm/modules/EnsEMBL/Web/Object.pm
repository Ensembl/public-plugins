package EnsEMBL::Web::Object;

## Plugin to EnsEMBL::Web::Object for the ORM specific Web::Object
## Handles multiple EnsEMBL::ORM::Rose::Object objects

use strict;
use warnings;

sub rose_manager {
  ## Returns the ORM::Rose::Manager class for the given type
  ## @return Manager Class (Static class reference) or undef if not found
  my ($self, $type) = @_;
  $type = $type ? "::$type" : '';

  return $self->{'_rose_managers'}{$type} ||= $self->dynamic_use_fallback("EnsEMBL::ORM::Rose::Manager$type");
}

sub rose_objects {
  ## Getter/Setter for the rose objects
  ## Baiscally this method takes the data across from Web::Object to the Web::Component, to keep 'business logic' away from Components
  ## Saves and returns Rose::Object drived objects
  ## @param Key name for saving the objects (optional) - defaults to saving (or retrieving from) as primary rose objects
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

  my %user = ('user' => delete $params->{'user'} || $self->hub->user);

  for (@{$self->rose_objects($type || '0')}) {
    if (my $obj = $_->save(%$params, $_->meta->is_trackable ? %user : ())) {
      push @$objs, $_;
    }
    else {
      push @{$self->{'_rose_error'}}, $_->error;
    }
  }

  return $objs;
}

sub delete {
  ## TODO
  warn "Delete is not supported. Instead, use 'retire' to flag the row as inactive";
}

sub retire {
  ## Alternative 'delete' - sets 'inactive_flag_column' to 'inactive_flag_value'
  ## @param Key for the rose objects - optional - defaults to the primary rose objects
  ## @return ArrayRef of successfully retired rose objects
  my ($self, $type) = @_;
  
  my $objs = [];

  my %user = ('user' => $self->hub->user);

  for (@{$self->rose_objects($type || '0')}) {
    my $meta    = $_->meta;
    my $column  = $meta->inactive_flag_column;
    my $value   = $meta->inactive_flag_value;
    if ($column) {
      $_->$column($value);
      if (my $obj = $_->save('changes_only' => 1, $meta->is_trackable ? %user : ())) {
        push @$objs, $obj;
      }
      else {
        push @{$self->{'_rose_error'}}, $_->error;
      }
    }
  }
  return $objs;
}

1;