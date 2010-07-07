package EnsEMBL::ORM::DbFrontend;

## NAME: EnsEMBL::ORM::DbFrontend
### A class for configuring automated database frontends

### STATUS: Under development

### DESCRIPTION:
### This module, and its associated modules in E::W::Command::DbFrontend
### and E::W::Component::DbFrontend, provide a way of automating the creation
### of database frontend whilst allowing extension of the basic functionality
### through custom forms etc.

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Root);

sub new {
  my ($class, $model) = @_;
  return unless ref($model->object) =~ /Data::Rose/;

  my $self = {
    'hub'                    => $model->hub,
    'show_fields'            => [],
    'record_select_query'    => {},
    'record_select_style'    => 'select',
    'record_select_columns'  => [],
    'record_table_columns'   => [],
    'show_preview'           => 1,
    'show_primary_key'       => 0,
    'show_tracking'          => 0,
    'delete_mode'            => 0,
  };

  bless $self, $class;

  ## Optional customisation
  $self->init($model->object);

  return $self;
}

sub init {
  my ($self, $object) = @_;

  ## Show all columns by default (note that we don't add relational columns 
  ## by default, as doing this using EnsEMBL::ORM::Rose::Column can break the 
  ## Rose::DB::Object::Metadata for reasons I don't currently understand!  
  my $all_columns = [];
  foreach my $column (@{$object->get_table_columns}) {
    push @$all_columns, $column->name; 
  } 

  $self->{'show_fields'} = $all_columns;
}

##----------- ACCESSORS ----------------------------------------

sub hub { my $self = shift; return $self->{'hub'}; }

sub show_fields { my $self = shift; return $self->{'show_fields'}; }

sub record_select_query { my $self = shift; return $self->{'record_select_query'}; }

sub record_select_style { my $self = shift; return $self->{'record_select_style'}; }

sub record_select_columns { my $self = shift; return $self->{'record_select_columns'}; }

sub record_table_columns { my $self = shift; return $self->{'record_table_columns'}; }

sub show_preview { my $self = shift; return $self->{'show_preview'}; }

sub show_primary_key { my $self = shift; return $self->{'show_primary_key'}; }

sub show_tracking { my $self = shift; return $self->{'show_tracking'}; }

sub delete_mode { my $self = shift; return $self->{'delete_mode'}; }

##-------------- Stubs for optional methods -------------------

sub modify_form {}



1;
