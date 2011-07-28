package EnsEMBL::ORM::Rose::MetaData;

## Name: EnsEMBL::ORM::Rose::MetaData
## MetaData class for all Rose Objects

use strict;

use EnsEMBL::ORM::Rose::ExternalRelationship;

use base qw(Rose::DB::Object::Metadata);

use constant EXTERNAL_RELATION => '__ens_external_relationships';

sub setup {
  ## @overrides
  ## Allows an extra key 'external_relationships' to be included in the argument hash to specify the relations of the given rose object with other rose objects that are not on the same database/host
  ## external_relationships accepts a hashref value as {relation name => {type => 'one to one' etc, class => rose object class name, column_map => {internal_column => external_column}}}
  ## If object's table is not residing in the user db, methods camouflaged as relationship methods are created
  my ($self, %params) = @_;
  
  if (my $external_relationships = delete $params{'external_relationships'}) {
    while (my $relationship_name = shift @$external_relationships) {
      $self->external_relationship($relationship_name, shift @$external_relationships);
    }
  }
  return $self->SUPER::setup(%params);
}

sub is_trackable {
  ## Tells whether the object isa Trackable object
  return 0;
}

sub external_relationship {
  ## Gets/sets an external relationship
  ## @param External relation name
  ## @param Hashref for keys: (optional - will return the existing saved relationship if missed)
  ##  - class       Name of the class of the related object
  ##  - column_map  Hashref of internal_column => external column mapping the relationshop
  ##  - type        one to one, many to one etc
  my ($self, $relationship_name, $params) = @_;
  
  my $object_class = $self->class;
  
  if ($params) {
    no strict 'refs';
    my $relationship = $self->{$self->EXTERNAL_RELATION}{$relationship_name} = EnsEMBL::ORM::Rose::ExternalRelationship->new({'name', $relationship_name, %$params});
    *{"${object_class}::$relationship_name"} = sub {
      return shift->external_relationship($relationship, @_);
    };
  }

  warn "External relationship '$relationship_name' not registered with $object_class." and return unless $self->{$self->EXTERNAL_RELATION}{$relationship_name};

  return $self->{$self->EXTERNAL_RELATION}{$relationship_name};
}

sub external_relationships {
  ## Gets all the external relationships
  return $_[0]->{$_[0]->EXTERNAL_RELATION} ||= {};
}

1;