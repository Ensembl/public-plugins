package EnsEMBL::ORM::Rose::VirtualColumn;

### Class to represent a virtual column which in actual is a key of a hash which is saved in a column as string
### It does not inherit rose's column object but has some similar methods

use strict;
use warnings;

use overload ('""'  => 'name');

sub new {
  ## @constructor
  ## @params Hashref with keys:
  ##  - name:   actual key name
  ##  - column: column name that created the hash saved as string
  ##  - alias:  alternative name to be used as a method name for rose object if key name is reserved in rose
  ##  - parent: Meta class of the rose object
  my ($class, $params) = @_;
  return bless $params, $class;
}

sub type                  { return 'virtual';                           }
sub name                  { return shift->{'name'};                     }
sub column                { return shift->{'column'};                   }
sub alias                 { return shift->{'alias'};                    }
sub parent                { return shift->{'parent'};                   }
sub accessor_method_name  { return $_[0]->{'alias'} || $_[0]->{'name'}; }
sub mutator_method_name   { return shift->accessor_method_name;         }

sub make_methods {
  ## Creates the method to access/modify the value from the rose object
  ## @param Hash with key target_class - rose object class name
  my ($self, %params) = @_;
  my $object_class = $params{'target_class'};
  my $method_name  = $self->accessor_method_name;

  no strict qw(refs);
  *{"${object_class}::${method_name}"} = sub {
    return shift->virtual_column_value($self, @_);
  };
}

1;