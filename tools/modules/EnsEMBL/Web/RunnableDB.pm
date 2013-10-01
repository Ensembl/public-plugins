package EnsEMBL::Web::RunnableDB;

### Parent class for all the runnabledb classes for different tools
### The child modules of this class are not used by the webserver directly, but are used by hive to actually run the bsubed jobs.
### Error handling: In any child classes, "throw exception('HiveException', 'message ..')" to passes them back to the web server

use strict;
use warnings;

use base qw(Bio::EnsEMBL::Hive::Process);

use EnsEMBL::Web::Exceptions;

sub param_required {
  ## @overrides
  ## Throws a HiveException in case a param is not defined and is required
  my ($self, $param_name) = @_;

  throw exception('HiveException', "Param '$param_name' is not defined.") unless $self->param_is_defined($param_name);

  return $self->param($param_name);
}

1;
