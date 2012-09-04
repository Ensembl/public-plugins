package EnsEMBL::ORM::Rose::ExternalRelationship;

### Name: EnsEMBL::ORM::Rose::ExternalRelationship
### A class for defining relationship of rose object to another rose object while the corrosponding db tables being on different hosts
### The class contains some essential methods as in Rose::DB::Object::Metadata::Relationship
### ExternalRelationship DOES NOT allow many to many relationship

use strict;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Tools::MethodMaker qw(add_method);

use base qw(EnsEMBL::Web::Root);

sub new {
  ## @constructor
  ## @param Hashref with keys:
  ##  - name        Relationship name
  ##  - type        Type of relationship - 'one to one' etc
  ##  - column_map  Hashref {internal_column => external_column} defining the link between relationship
  ##  - class       Class name of the object mapped
  ## @exception ORMException::ObjectClassMissingException if the class for the related object is not found
  my ($class, $params) = @_;

  $class->dynamic_use($params->{'class'}) or
  throw exception('ORMException::ObjectClassMissingException', sprintf("External relationship mapping class '%s' could not be found.", $params->{'class'}));

  return bless $params, $class;
}

sub class       { return shift->{'class'};                      }
sub name        { return shift->{'name'};                       }
sub type        { return shift->{'type'};                       }
sub column_map  { return shift->{'column_map'};                 }
sub is_singular { return shift->type =~ /to one$/ ? 1 : undef;  }

sub make_methods {
  ## Creates the method to access/modify the value of the related rose object
  ## @param Hash with key target_class - rose object class name
  my ($self, %params) = @_;

  add_method($params{'target_class'}, $self->name, sub {
    return shift->external_relationship_value($self, @_);
  });
}

1;