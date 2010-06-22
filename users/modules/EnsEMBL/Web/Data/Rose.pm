package EnsEMBL::Web::Data::Rose;

### NAME: EnsEMBL::Web::Data::Rose
### Base class - wrapper around one or more EnsEMBL::Data objects 

### STATUS: Under Development

### DESCRIPTION:
### This module and its children provide additional data-handling
### capabilities on top of those provided by Rose::DB::Object

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::Data::DBSQL::Column; 

use base qw(EnsEMBL::Web::Data);

sub _init {
  my $self = shift;
  $self->{'_relationships'} = {};
  $self->_set_relationships;
  $self->{'_managers'} = $self->set_managers;
  $self->populate;
}

##------- OBJECT INITIATION -----------

sub _set_relationships {
## Stub - has to be implemented in child modules
  my $self = shift;
}

sub set_managers {
  my $self = shift;
  my $class = 'EnsEMBL::Data::Manager::'.$self->type;
  $self->manager($self->type, $class);
  $self->_extra_managers;
}

sub _extra_managers {
## Stub - implement in child module if needed
}

sub populate {
  my $self = shift;
  my @objects;

  if ($self->hub->param('id')) {
    @objects = @{$self->fetch_by_id};
  }
  else {
    @objects = @{$self->fetch_all};
  }
  $self->data_objects(@objects);
}

##----------- ACCESSORS ---------------

sub manager {
## Accessor for the class's Rose::DB::Manager classes
  my ($self, $type, $manager) = @_;
  $type ||= $self->type;
  if ($manager) {
    $self->{'_manager'}{$type} = $manager;
  }
  return $self->{'_manager'}{$type};
}

sub fetch_all { return []; }

sub fetch_by_id { return []; }

sub related_object {
## Retrieves an object joined by a given foreign key
  my ($self, $foreign_key) = @_;
  return unless $foreign_key;
  return $self->{'_relationships'}{$foreign_key};
}

sub get_all_columns {
### Returns all database columns needed to populate a web form
  my $self = shift;
  my $data_object = $self->data_objects->[0];
  my $columns = [];

  ## Get all columns from main table
  if ($data_object) {
    $columns = $data_object->meta->columns;
  }

  ## Get relational "columns"
  foreach my $rel (@{$data_object->meta->relationships}) {
    next unless $rel->type eq 'many to many';
    my $class = $rel->map_class;
    if ($class && $self->dynamic_use($class)) {
      my $mapper = $class->new();
      my $map_rel = $mapper->meta->relationship($rel->name);
      my $manager = $map_rel->manager_class;
      if ($manager && $self->dynamic_use($manager)) {
        my $values = $manager->get_lookup;
        my $col = EnsEMBL::Data::DBSQL::Column->new({ 
          'name'    => $rel->name,
          'type'    => 'set',
          'values'  => $values,
        });
        push @$columns, $col;
      }
    }
  }

  return $columns;
}

1;
