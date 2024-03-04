=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Record;

### Wrapper around ORM::EnsEMBL::DB::Accounts::Object::Record for use in the web code

### For backward compatibility
### This packages replaces EnsEMBL::Web::Data::Record temporarily for object type UserData, untill UserData is properly re-written to make methods calls to actual Rose Record object instead of using hash keys
### Objects belonging to this class is only returned by EnsEMBL::Web::User::get_record or get_user_record(s) methods

use strict;
use warnings;

use EnsEMBL::Web::Utils::MethodMaker qw(add_method);

use ORM::EnsEMBL::DB::Accounts::Manager::Record;

use parent qw(EnsEMBL::Web::Root);

sub new {
  ## @constructor
  ## @param Record id
  my ($class, $record_id) = @_;
  return [ $class->from_rose_objects([ ORM::EnsEMBL::DB::Accounts::Manager::Record->fetch_by_primary_key($record_id) || () ]) ]->[0];
}

sub from_rose_objects {
  ## @constructor
  ## Wraps rose record objects in web record objects
  ## @param ArrayRef of rose record objects
  ## @return List of Web::Record objects (one object for each rose object in the argument arrayref)
  my ($class, $rose_objects) = @_;

  my @keys = @$rose_objects ? map { $_->alias || $_->name } $rose_objects->[0]->meta->virtual_columns : ();

  return map {
    my $rose_object = $_;
    my $record      = $_->as_tree;
    $record->{$_}   = $rose_object->$_ for @keys;

    $record->{'__rose_object'} = $_;
    delete $record->{'data'};

    $class->_new($record);
  } @$rose_objects;
}

sub id {
  return shift->{'record_id'};
}

sub colour { # some calls are made to this method while it's key may not be added to the object
  return shift->data->{'colour'};
}

sub assembly { # We store assembly ID in an arbitrary field
  return shift->data->{'module_version'};
}

sub clone {
  my $self        = shift;
  my $class       = ref $self;
  my $rose_object = delete $self->{'__rose_object'};
  my $clone       = $self->deepcopy($self);
  $self->{'__rose_object'} = $rose_object;
  $clone->{'__rose_object'} = $rose_object->clone_and_reset;
  $clone->{'__rose_object'}->cloned_from($self->id);
  $clone->{'cloned_from'} = $self->id;
  return $class->_new($clone);
}

sub owner {
  my ($self, $owner)  = @_;
  my $rose_object     = $self->{'__rose_object'};
  $rose_object->record_type($owner->RECORD_TYPE);
  $rose_object->record_type_id($owner->get_primary_key_value);
  return $rose_object->record_type eq 'group' ? $rose_object->group : $rose_object->user;
}

sub save {
  ## Saves the record to db
  ## @param As accepted by ORM::EnsEMBL::DB::Accounts::Object::Record->save method (except that user argument can be EnsEMBL::Web::User instead of ORM::EnsEMBL::DB::Accounts::Object::User)
  my ($self, %params) = @_;
  $params{'user'} = $params{'user'}->rose_object if $params{'user'} && $params{'user'}->isa('EnsEMBL::Web::User');
  $self->{'__rose_object'}->save(%params);
}

sub delete {
  ## Deletes the record from the db
  shift->{'__rose_object'}->delete(@_);
}

sub cloned_from {
  return shift->{'cloned_from'};
}

sub data {
  shift->{'__rose_object'}->data(@_);
}

sub _new {
  ## @private
  my ($class, $object) = @_;
  foreach my $key (keys %$object) {
    add_method($class, $key, sub { return shift->{$key}; }) unless $class->can($key) && $key =~ /^_/;
  }
  return bless $object, $class;
}
1;
