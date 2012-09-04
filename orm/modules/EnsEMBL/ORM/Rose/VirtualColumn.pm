package EnsEMBL::ORM::Rose::VirtualColumn;

### Class to represent a virtual column which in actual is a key of a hash which is saved in a column as string
### It does not inherit rose's column object but has some similar methods

use strict;
use warnings;

use EnsEMBL::Web::Tools::MethodMaker qw(add_method);

use overload qw("" name);

sub new {
  ## @constructor
  ## @params Hashref with keys:
  ##  - name:     actual key name
  ##  - column:   column name that created the hash saved as string
  ##  - alias:    alternative name to be used as a method name for rose object if key name is reserved in rose
  ##  - parent:   Meta class of the rose object
  ##  - default:  Default value
  my ($class, $params) = @_;
  return bless $params, $class;
}

sub type                  { return 'virtual';                                               }
sub name                  { return shift->{'name'};                                         }
sub column                { return shift->{'column'};                                       }
sub alias                 { return shift->{'alias'};                                        }
sub parent                { return shift->{'parent'};                                       }
sub default_exists        { return exists $_[0]->{'default'} && defined $_[0]->{'default'}; }
sub delete_default        { return shift->{'default'} = undef;                              }
sub accessor_method_name  { return $_[0]->{'alias'} || $_[0]->{'name'};                     }
sub mutator_method_name   { return shift->accessor_method_name;                             }

sub default {
  ## Sets/Gets the default value of the virtual column
  my $self = shift;
  $self->{'default'} = shift if @_;
  return $self->{'default'};
}

sub make_methods {
  ## Creates the method to access/modify the value from the rose object
  my $self = shift;

  add_method($self->parent->class, $self->accessor_method_name, sub {
    return shift->virtual_column_value($self, @_);
  });
}

1;