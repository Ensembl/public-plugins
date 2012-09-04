package EnsEMBL::ORM::Rose::MetaData;

## Name: EnsEMBL::ORM::Rose::MetaData
## MetaData class for all Rose Objects

use strict;

use EnsEMBL::ORM::Rose::VirtualColumn;
use EnsEMBL::ORM::Rose::VirtualRelationship;
use EnsEMBL::ORM::Rose::ExternalRelationship;

use EnsEMBL::Web::Exceptions;

use base qw(Rose::DB::Object::Metadata);

use constant {
  EXTERNAL_RELATIONS_KEY_NAME => '__ens_external_relationships',
  VIRTUAL_COLUMNS_KEY_NAME    => '__ens_virtual_columns',
  VIRTUAL_RELATIONS_KEY_NAME  => '__ens_virtual_relationships'
};

sub setup {
  ## @overrides
  my ($self, %params) = @_;
  my @args;

  ## sort arguments to keep table name, columns and relationships before any other keys (to make sure virtual columns, virtual relationships are initiated after columns and relationships)
  splice @args, ($_ =~ /^(table|columns|relationships)$/ ? 0 : @args), 0, $_, $params{$_} for keys %params;

  return unless $self->SUPER::setup(@args);

  ## Call modify_methods method on datastructure based columns
  $_->isa('EnsEMBL::ORM::Rose::DataStructure') and $_->modify_methods for $self->columns;
  return 1;
}

sub is_trackable {
  ## Tells whether the object isa Trackable object
  ## Overridden in MetaData::Trackable
  return 0;
}

sub virtual_columns {
  ## Method to set/get the virtual columns that are actually keys of some other column of type datamap
  ## @param Column names and details (hashref containtng key 'column' (required) and 'alias' (optional)) as a hash in arrayref syntax
  ## @return Array and Arrayref of the virtual column objects in list and scalar context respectively
  my $self      = shift;
  my $key_name  = $self->VIRTUAL_COLUMNS_KEY_NAME;

  if (@_) {

    my $object_class    = $self->class;
    $self->{$key_name}  = [];

    while (my ($col, $detail) = splice @_, 0, 2) {

      # only a datamap column can have virtual columns
      my $datamap = $self->column($detail->{'column'});
      throw exception('ORMException::DataMapMissing', "No datamap column with name '$detail->{'column'}' found. Either this column name is invalid or columns need to be added before adding virtual columns") unless $datamap;
      throw exception('ORMException::InvalidDataMap', "Column '$detail->{'column'}' is required to be of type 'datamap' for adding virtual columns to it.") unless $datamap->type eq 'datamap';

      my $column  = EnsEMBL::ORM::Rose::VirtualColumn->new({
        'name'    => $col,
        'column'  => $datamap,
        'parent'  => $self,
        'alias'   => $detail->{'alias'} || undef,
        'default' => defined $detail->{'default'} ? $detail->{'default'} : undef
      });
      $column->make_methods;

      push @{$self->{$key_name}}, $column;
    }
  }
  return wantarray ? @{$self->{$key_name} || []} : [ map {$_} @{$self->{$key_name} || []} ];
}

sub virtual_column_names {
  ## Gets the names of all the virtual columns of the related object
  ## @return Array and Arrayref of the virtual column names in list and scalar context respectively
  my $self = shift;
  my @cols = map {$_->name} @{$self->{$self->VIRTUAL_COLUMNS_KEY_NAME}};
  return wantarray ? @cols : \@cols;
}

sub virtual_column {
  ## Gets the virtual column object for the given column name
  ## @param   Virtual column name
  ## @return  Virtual column object if found, undef otherwise
  my ($self, $column_name) = @_;
  $_->name eq $column_name and return $_ for @{$self->{$self->VIRTUAL_COLUMNS_KEY_NAME}};
  return undef;
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
  my $key_name     = $self->EXTERNAL_RELATIONS_KEY_NAME;
  
  if ($params) {
    my $relationship = $self->{$key_name}{$relationship_name} = EnsEMBL::ORM::Rose::ExternalRelationship->new({'name', $relationship_name, %$params});
    $relationship->make_methods('target_class' => $object_class);
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
  return [values %{$self->{$self->EXTERNAL_RELATIONS_KEY_NAME} ||= {}}];
}

sub virtual_relationships {
  ## Gets/sets virtual relationships - relationships that actually fall under a common relationship, but have a condition that is used to differentiate them
  ## @param Relationship names and details (hashref containtng key 'relationship' and 'condition' - both required) as a hash in arrayref syntax
  ## @return Array and Arrayref of the virtual relationship objects in list and scalar context respectively
  my $self      = shift;
  my $key_name  = $self->VIRTUAL_RELATIONS_KEY_NAME;

  if (@_) {

    my $object_class    = $self->class;
    $self->{$key_name}  = [];

    while (my ($relationship_name, $detail) = splice @_, 0, 2) {

      # only a datamap column can have virtual columns
      my $relationship = $self->relationship($detail->{'relationship'});
      throw exception('ORMException::RelationshipMissing', "No relationship with name '$detail->{'relationship'}' found. Either this relationship name is invalid or relationships need to be added before adding virtual relationships") unless $relationship;
      throw exception('ORMException::InvalidRelationshipType', "Relationship '$detail->{'relationship'}' is required to be of type '* to many' for categorising it into virtual relationships.") unless $relationship->type =~ /to many$/;

      my $virtual_relationship = EnsEMBL::ORM::Rose::VirtualRelationship->new({'name' => $relationship_name, 'relationship' => $relationship, 'condition' => $detail->{'condition'}, 'parent' => $self});
      $virtual_relationship->make_methods;

      push @{$self->{$key_name}}, $virtual_relationship;
    }
  }
  return wantarray ? @{$self->{$key_name} || []} : [ map {$_} @{$self->{$key_name} || []} ];
}

sub virtual_relationship {
  ## Gets the virtual relationship object for the given name
  ## @param   Virtual relationship name
  ## @return  Virtual relationship object if found, undef otherwise
  my ($self, $relation_name) = @_;
  $_->name eq $relation_name and return $_ for @{$self->{$self->VIRTUAL_RELATIONS_KEY_NAME}};
  return undef;
}

1;