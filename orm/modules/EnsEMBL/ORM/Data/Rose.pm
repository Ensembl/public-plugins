package EnsEMBL::ORM::Data::Rose;

### NAME: EnsEMBL::ORM::Data::Rose
### Base class - wrapper around one or more EnsEMBL::ORM::Rose objects 

### STATUS: Under Development

### DESCRIPTION:
### This module and its children provide additional data-handling
### capabilities on top of those provided by Rose::DB::Object

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::Column; 

use base qw(EnsEMBL::Web::Data);

sub _init {
  my $self = shift;
  $self->{'_object_class'}  = undef;
  $self->{'_manager_class'} = undef;
  $self->{'_primary_keys'}  = [];
  $self->{'_relationships'} = {};

  $self->set_classes;
  $self->set_primary_keys;
  $self->populate;
}

##------- OBJECT INITIATION -----------

## Some of these are set manually, to avoid the overhead 
## of creating an empty object and then interrogating it

sub set_classes {
## Override this in children, if namespace is different
  my $self = shift;
  $self->{'_object_class'} = 'EnsEMBL::ORM::Rose::Object::'.$self->type;
  $self->{'_manager_class'} = 'EnsEMBL::ORM::Rose::Manager::'.$self->type;
}

sub set_primary_keys {
## This will probably need overriding unless you are creating 
## a new table from scratch with a generic primary key
  my $self = shift;
  $self->{'_primary_keys'} = [qw(id)];
}

sub populate {
  my $self = shift;
  my @objects;

  if ($self->hub->param('id')) {
    my @ids = ($self->hub->param('id'));
    @objects = @{$self->fetch_by_id(\@ids)};
  }
  $self->data_objects(@objects);
}

##----------- ACCESSORS ---------------

sub object_class { return $_[0]->{'_object_class'}; }
sub manager_class { return $_[0]->{'_manager_class'}; }

sub primary_keys { return $_[0]->{'_primary_keys'}; }
sub primary_key  { return $_[0]->{'_primary_keys'}[0]; }

## ------ Data manipulation -----------

sub fetch_all {
  my $self = shift;
  my $objects = $self->manager_class->get_objects(object_class => $self->object_class);
  $self->data_objects(@$objects);
  return $objects;
}

sub fetch_by_id { 
  my ($self, $ids) = @_;
  my $objects = $self->manager_class->get_objects(
                  query => [$self->primary_key => $ids], 
                  object_class => $self->object_class,
                );
  return $objects; 
}

sub get_table_columns {
### Returns all database columns needed to populate a web form
  my $self = shift;
  my $data_object = $self->data_objects->[0] || $self->create_empty_object;
  my $columns = [];

  ## Get all columns from main table
  if ($data_object) {
    $columns = $data_object->meta->columns;
  }

  return $columns;
}

sub get_related_columns {
### Forms need dummy columns representing relational objects that can
### be attached to the main domain object
  my $self = shift;
  my $data_object = $self->data_objects->[0] || $self->create_empty_object;
  my $managers = $self->_get_m2m_managers($data_object);
  my $columns = [];
  
  while (my ($name, $manager) = each (%$managers)) {
    my $values = $manager->get_lookup;
    my $col = EnsEMBL::ORM::Rose::Column->new({ 
      'name'    => $name,
      'type'    => 'set',
      'values'  => $values,
    });
    push @$columns, $col;
  }

  return $columns;
}

sub _get_m2m_managers {
  my ($self, $data_object) = @_;
  return unless $data_object;
  my $managers = {};

  foreach my $rel (@{$data_object->meta->relationships}) {
    next unless $rel->type eq 'many to many';
    my $class = $rel->map_class;
    if ($class && $self->dynamic_use($class)) {
      my $mapper = $class->new();
      my $map_rel = $mapper->meta->relationship($rel->name);
      my $manager = $map_rel->manager_class;
      if ($manager && $self->dynamic_use($manager)) {
        $managers->{$rel->name} = $manager;
      }
    }
  }
  return $managers;
}

sub create_empty_object {
  my $self = shift;
  my $class = shift || $self->object_class;
  return $class->new();
}

sub populate_from_cgi {
### Set the value of each column in the data object(s) from CGI parameters
## TODO - allow multiple domain objects to be populated
  my $self = shift;
  my $hub = $self->hub;
  my @param_names = $hub->param;

  ## Create an empty Data object if there is none
  my $object = $self->data_objects->[0];
  unless ($object) {
    $object = $self->create_empty_object;
    $self->data_objects($object);
  }

  ## Populate the main object first
  foreach my $column (@{$object->meta->columns}) {
    my $field = $column->name;
    next unless grep {$_ eq $field} @param_names;
    my $value = (scalar(@{[$hub->param($field)]}) > 1)
                ? [$hub->param($field)]
                : $hub->param($field);
    $object->$field($value) if $value;
  }

  ## Populate any dependent objects from the database
  my $managers = $self->_get_m2m_managers($object);
  while (my ($field, $manager) = each (%$managers)) {
    my @ids = ($hub->param($field));
    (my $m2m_class = $manager) =~ s/Manager/Object/;
    if (@ids) {
      my $empty = $m2m_class->new();
      my @keys = $empty->meta->primary_key_column_names;
      $object->$field($manager->get_objects(
                  query => [$keys[0] => \@ids],
                  object_class => $m2m_class,
      ));
    }
  }
}

sub save {
## Wrapper to Rose::DB::Object's save method, automatically adding web-friendly error-handling
  my $self = shift;
  my $ids = [];
  my $primary_key = $self->primary_key;
  foreach (@{$self->data_objects}) {
    my $update = $_->$primary_key ? 1 : 0;
    my $id = $_->save('update' => $update, 'changes_only' => 1);
    if ($_->error) {
      warn $_->error;
    }
    else {
      push @$ids, $_->$primary_key;
    }
  }
  return $ids;
}

1;
