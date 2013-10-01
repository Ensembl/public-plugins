package EnsEMBL::Web::Exception::HiveException;

### Exception class to be used in the Hive RunnableDB scripts
### If an error occurs in hive, it saves the error string to its database. Thus this class returns JSON string as an error string which is further used by the web server to handle those errors.

use strict;
use warnings;

use JSON qw(to_json from_json);

use base qw(EnsEMBL::Web::Exception);

sub to_string {
  ## @overrides
  ## Converts the Exception object into a JSON string
  return to_json(shift->_to_hash);
}

sub handle {
  ## @static
  ## Handles the exception
  ## @param Exception JSON string
  ## @param Subroutine to be called to handle this exception
  ## @params List of extra arguments for the given subroutine
  my ($exception, $sub) = splice @_, 0, 2;
  return $sub->(_to_hash($exception), @_);
}

sub _to_hash {
  ## @private
  ## Converts an exception object (or it's JSON representation) to a simple hash
  my $self = shift;
  if (ref $self) {
    return {
      'class' => ref $self,
      map {( substr($_, 1),  $self->{$_})} keys %$self
    };
  } else { # converting from JSON string
    return from_json($self);
  }
}

1;
