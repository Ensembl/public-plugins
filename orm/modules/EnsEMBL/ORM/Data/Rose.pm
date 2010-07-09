package EnsEMBL::ORM::Data::Rose;

### NAME: EnsEMBL::ORM::Data::Rose
### Base class - wrapper around one or more EnsEMBL::ORM::Rose::Object objects 

### STATUS: Under Development

### DESCRIPTION:
### This module and its children provide additional data-handling
### capabilities on top of those provided by Rose::DB::Object, in particular,
### access to web parameters via the Hub

### Some wrapper methods are provided, but all Rose::Object::Manager functionality 
### can be accessed directly, e.g. $self->manager_class->get_<tablename>s_count

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

  $self->set_classes;
  $self->set_primary_keys;
  $self->populate;
}

##----------- ACCESSORS ---------------

sub object_class { return $_[0]->{'_object_class'}; }
sub manager_class { return $_[0]->{'_manager_class'}; }

sub primary_keys { return $_[0]->{'_primary_keys'}; }
sub primary_key  { return $_[0]->{'_primary_keys'}[0]; }

##------- OBJECT INITIATION -----------

sub set_classes {
### Defines the classes of the Rose::Object and Rose::Manager - defaults
### to the namespace of this plugin, but can be overridden in the child class
### This is set manually, to avoid the overhead  of creating an empty object 
### and then interrogating it
  my $self = shift;
  $self->{'_object_class'} = 'EnsEMBL::ORM::Rose::Object::'.$self->type;
  $self->{'_manager_class'} = 'EnsEMBL::ORM::Rose::Manager::'.$self->type;
}

sub set_primary_keys {
### Defines the primary key(s) used by the main object - defaults to 'id'
### This is set manually, to avoid the overhead  of creating an empty object 
### and then interrogating it
### It will probably need overriding unless you are creating 
### a new table from scratch with a primary key 'id'!
  my $self = shift;
  $self->{'_primary_keys'} = [qw(id)];
}

sub populate {
### A factory-type method that can generate one or more domain objects from
### a set of IDs - defaults to using the CGI parameter 'id' if no argument
### is passed
### Argument (optional) - an array of primary key values
  my ($self, @ids) = @_;
  my @objects;

  if (!@ids && $self->hub->param('id')) {
    @ids = ($self->hub->param('id'));
    warn "IDs @ids";
    @objects = @{$self->fetch_by_id(\@ids)};
  }
  $self->data_objects(@objects);
}

## ------ Data manipulation -----------

sub fetch_all {
### Wrapper around the Rose::Manager's get_objects method - defaults to returning all
### the records in a table
  my $self = shift;
  my $objects = $self->manager_class->get_objects(object_class => $self->object_class);
  $self->data_objects(@$objects);
  return $objects;
}

sub fetch_by_id { 
### Wrapper around the Rose::Manager's get_objects method
### Argument - arrayref containing values of primary key
  my ($self, $ids) = @_;
  my $objects = $self->manager_class->get_objects(
                  query => [$self->primary_key => $ids], 
                  object_class => $self->object_class,
                );
  return $objects; 
}

sub fetch_by_page {
### Used with the (optional) pagination parameter to retrieve a set of objects
  my ($self, $pagination) = @_;
  my $page = $self->hub->param('page') || 1;
  my $offset = ($page - 1) * $pagination;

  my $objects = $self->manager_class->get_objects(
                  limit => $pagination,
                  offset => $offset,
                  object_class => $self->object_class,
                );
  return $objects; 
}

sub count {
  my $self = shift;
  my $count = $self->manager_class->get_objects_count(
                object_class => $self->object_class,
              );
  return $count;
}

sub get_table_columns {
### Returns all columns from a table - used to populate a web form
  my $self = shift;
  my $data_object = $self->data_objects->[0] || $self->create_empty_object;
  my $columns = [];

  ## Get all columns from main table
  if ($data_object) {
    $columns = $data_object->meta->columns;
  }

  return $columns;
}

sub get_m2m_columns {
### Forms may need dummy columns, representing many-to-many relational 
### objects that can be attached to the main domain object
  my $self = shift;
  my $data_object = $self->data_objects->[0] || $self->create_empty_object;
  my $managers = $self->_get_m2m_managers($data_object);
  my $columns = [];
  
  while (my ($name, $manager) = each (%$managers)) {
    my $values = $manager->get_lookup($self->hub);
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
### Helper method to get information about many-to-many relationships
### Returns a hashref of relationship => manager_class_name pairs,
### e.g. 'species' => 'EnsEMBL::ORM::Rose::Manager::Species'
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

sub get_m2o_lookups {
  my $self = shift;
  my $data_object = $self->data_objects->[0] || $self->create_empty_object;
  my $lookups = {};
 
  foreach my $rel (@{$data_object->meta->relationships}) {
    next unless $rel->type eq 'many to one';
    my @keys = keys %{$rel->column_map};
    my $fk = $keys[0];
    my $class = $rel->manager_class;
    ## Fall back to a default if undefined
    unless ($class) {
      ($class = $rel->class) =~ s/Object/Manager/;
    }
    if ($class && $self->dynamic_use($class)) {
      $lookups->{$fk} = $class->get_lookup($self->hub);
    }
  }

  return $lookups;
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
### Wrapper to Rose::DB::Object's save method, automatically adding web-friendly error-handling
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

sub delete {
  my $self = shift;
}

sub retire {
### Alternative 'delete' - sets a flag in the database to a suitable status
### such as 'dead' or 'cancelled'
  my ($self, $permit_delete) = @_;
  my ($field, $value) = @$permit_delete;

  my $ids = [];
  my $primary_key = $self->primary_key;
  foreach (@{$self->data_objects}) {
    $_->$field($value);
    my $id = $_->save('update' => 1, 'changes_only' => 1);
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
