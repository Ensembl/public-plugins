package EnsEMBL::ORM::Rose::MetaData;

## Name: EnsEMBL::ORM::Rose::MetaData
## MetaData class for all Rose Objects

use strict;

use EnsEMBL::ORM::Rose::ExternalRelationship;
use EnsEMBL::Web::Exceptions;

use base qw(Rose::DB::Object::Metadata);

use constant EXTERNAL_RELATION_KEY_NAME => '__ens_external_relationships';

sub setup {
  ## @overrides
  ## Calls modify_methods method on datastructure based columns after doing the setup
  my $self = shift;
  return unless $self->SUPER::setup(@_);
  $_->isa('EnsEMBL::ORM::Rose::DataStructure') and $_->modify_methods for $self->columns;
  return 1;
}

sub is_trackable {
  ## Tells whether the object isa Trackable object
  ## Overridden in MetaData::Trackable
  return 0;
}

sub title_column {
  ## Method of set/get the name of the column containg the title of the row
  ## @param Column name as string
  ## @return Column name as string
  my $self = shift;
  $self->{'_ens_title_column'} = shift if @_;
  return $self->{'_ens_title_column'};
}

sub inactive_flag_column {
  ## Method of set/get the name of the column used as a flag to tell whether the row should be considered active or not
  ## @param Column name as string
  ## @return Column name as string
  my $self = shift;
  $self->{'_ens_inactive_flag_column'} = shift if @_;
  return $self->{'_ens_inactive_flag_column'};
}

sub inactive_flag_value {
  ## Method of set/get the value to which if inactive_flag_column is set, row is considered as inactive
  ## @param String value
  ## @return String value
  my $self = shift;
  $self->{'_ens_inactive_flag_value'} = shift if @_;
  return $self->{'_ens_inactive_flag_value'} || '0';
}

sub external_relationship {
  ## Gets/sets an external relationship
  ## @param External relation name
  ## @param Hashref for keys: (optional - will return the existing saved relationship if missed)
  ##  - class       Name of the class of the related object
  ##  - column_map  Hashref of internal_column => external column mapping the relationshop
  ##  - type        one to one, many to one etc
  ## @exception ORMException::UnknownRelation if no relation found for given name (only when used as getter)
  my ($self, $relationship_name, $params) = @_;
  
  my $object_class = $self->class;
  my $key_name     = $self->EXTERNAL_RELATION_KEY_NAME;
  
  if ($params) {
    no strict qw(refs);
    my $relationship = $self->{$key_name}{$relationship_name} = EnsEMBL::ORM::Rose::ExternalRelationship->new({'name', $relationship_name, %$params});
    *{"${object_class}::$relationship_name"} = sub {
      return shift->external_relationship_value($relationship, @_);
    };
  }

  throw exception('ORMException::UnknownExternalRelationException', "External relationship '$relationship_name' not registered with $object_class.") unless $self->{$key_name}{$relationship_name};

  return $self->{$key_name}{$relationship_name};
}

sub external_relationships {
  ## Gets/sets all the external relationships
  ## Functionality similar to Rose::Db::Object::Metadata::relationships method, but not same
  ## Methods camouflaged as relationship methods are created if two related objects not residing on the same table
  ## @param Hash of name - settings pair for external relationships (setting is hashref with keys class, column_map and type)
  my ($self, %relationships) = @_;
  while (my ($name, $settings) = each %relationships) {
    $self->external_relationship($name, $settings);
  }
  return [values %{$self->{$self->EXTERNAL_RELATION_KEY_NAME} ||= {}}];
}

1;