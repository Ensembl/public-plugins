package EnsEMBL::ORM::Rose::VirtualRelationship;

### Class to represent a virtual relationship which in actual a part of another relationship but is differentiated with a condition
### It does not inherit rose's relationship object but has some similar methods

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Tools::MethodMaker qw(add_method);

use overload ('""'  => 'name');

sub new {
  ## @constructor
  ## @params Hashref with keys:
  ##  - name:         name of the virtual relation - all methods will be created with this name
  ##  - relationship: actual relationship object
  ##  - condition:    Hashref - column-value pair that categorises this virtual relationship
  ##  - parent:       Meta class of the rose object
  my ($class, $params) = @_;
  return bless $params, $class;
}

sub type                  { return shift->relationship->type;           }
sub name                  { return shift->{'name'};                     }
sub relationship          { return shift->{'relationship'};             }
sub parent                { return shift->{'parent'};                   }
sub condition             { return shift->{'condition'};                }

sub method_name           {
  my ($self, $method_type) = @_;

  my $name = $self->name;

  return {
    'count'           => "${name}_count",
    'find'            => "find_$name",
    'iterator'        => "iterator_$name",
    'get_set'         => $name,
    'get_set_now'     => $name,
    'get_set_on_save' => $name,
    'add_now'         => "add_$name",
    'add_on_save'     => "add_$name",
  }->{$method_type};
}

sub make_methods {
  ## Creates the method to access/modify the value from the rose object
  ## @param Hash with key target_class - rose object class name
  my $self          = shift;
  my $target_class  = $self->parent->class;

  # get_related_objects
  add_method($target_class, $self->method_name('get_set_on_save'), sub {
    return shift->virtual_relationship_value($self, @_);
  });

  # add_related_objects
  add_method($target_class, $self->method_name('add_on_save'), sub {
    my ($object, $values) = @_;
    my $condition = $self->condition;
    foreach my $value (@$values) {
      if (ref $value eq 'HASH') {
        $value = { %$value, %$condition };
      } else {
        $value->column_value($_, $condition->{$_}) for keys %$condition;
      }
    }
    return $object->$_($values) for $self->relationship->method_name('add_on_save');
  });

  # find_related_objects
  add_method($target_class, $self->method_name('find'), sub {
    my $object    = shift;
    my $condition = $self->condition;
    my $values    = [];

    VALUE:
    foreach my $value (map { @{$object->$_(@_)} } $self->relationship->method_name('find')) {
      $value->column_value($_) ne $condition->{$_} and next VALUE for keys %$condition;
      push @$values, $value;
    }
    return $values;
  });

  # count_related_objects
  add_method($target_class, $self->method_name('count'), sub {
    my ($object, %params) = @_;
    my $method            = $self->relationship->method_name('count') or throw exception('ORMException::MethodMissing', "Method to count the related objects does not exist in the object class. Specify a 'method' key for the required relationship in the given object class to create default methods.");
    my $condition         = $self->condition;
    $params{'query'}      = [ @{$params{'query'} || []}, %$condition ];

    return $object->$method(%params);
  });

  #TODO other methods
}

1;