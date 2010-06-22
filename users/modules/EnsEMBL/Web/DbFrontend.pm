package EnsEMBL::Web::DbFrontend;

## NAME: EnsEMBL::Web::DbFrontend
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

  ## Set default values
  my $all_columns = [];
  foreach my $column (@{$model->object->get_all_columns}) {
    push @$all_columns, $column->name; 
  } 

  my $self = {
    'hub'              => $model->hub,
    'show_fields'      => $all_columns,
    'dropdown_query'   => {},
    'option_columns'   => [],
    'show_preview'     => 1,
    'show_primary_key' => 0,
    'show_history'     => 0,
    'delete_mode'      => 0,
  };

  bless $self, $class;

  ## Optional customisation
  $self->init;

  return $self;
}

sub init {}

##----------- ACCESSORS ----------------------------------------

sub hub { my $self = shift; return $self->{'hub'}; }

sub show_fields { my $self = shift; return @{$self->{'show_fields'}}; }

sub dropdown_query { my $self = shift; return $self->{'dropdown_query'}; }

sub option_columns { my $self = shift; return @{$self->{'option_columns'}}; }

sub show_preview { my $self = shift; return $self->{'show_preview'}; }

sub show_primary_key { my $self = shift; return $self->{'show_primary_key'}; }

sub show_history { my $self = shift; return $self->{'show_history'}; }

sub delete_mode { my $self = shift; return $self->{'delete_mode'}; }

##-------------- Stubs for optional methods -------------------

sub modify_form {}



1;
