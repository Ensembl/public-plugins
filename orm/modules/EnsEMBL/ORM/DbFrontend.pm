package EnsEMBL::ORM::DbFrontend;

### NAME: EnsEMBL::ORM::DbFrontend
### A base class for configuring automated database frontends

### STATUS: Under development

### DESCRIPTION:
### This module is used to configure the Component::DbFrontend modules used 
### by the Ensembl CRUD framework. It is a simple container for a set of 
### configuration variables, most of which are optional as the interface falls
### back to default values if they are not set:

### hub                     the Hub object (in case subclasses need access to 
###                         glabal variables)
### show_fields             Array of column names, defining which columns 
###                         are displayed on 'Add' and 'Edit' pages (if not set, 
###                         the default behaviour of the interface is to show
###                         all columns in the same order as the database table)
### record_table_columns    Array of column names which are displayed in the 
###                         table section of the 'List' component (defaults to
###                         primary key plus up to 50 characters of the next three 
###                         columns in the table)
### record_select_columns   Array of column names which are displayed in the
###                         'SelectToEdit' dropdown element (defaults to primary 
###                         key plus the next column in the table)
### record_select_query     Query parameters for the list of records shown in the
###                         'SelectToEdit' dropdown, using the same syntax as
###                         Rose::DB::Object (defaults to all records in the table)
### record_select_style     Parameter for the 'SelectToEdit' form widget, so that it
###                         can optionally be a radio button set (defaults to dropdown)
### pagination              Number of records to show on the 'List' and 'Display'
###                         pages (default of 0 means 'show all') 
### show_preview            Boolean flag - show 'Preview' step between adding/editing
###                         a record and saving it (default is 1)
### show_primary_key        Boolean flag - show primary key on 'Add' and 'Edit'
###                         pages (default is 0)
### show_tracking           Boolean flag - if the table has created/modified fields,
###                         should these be shown (default is 0)
### permit_delete           Defines whether and how records can be deleted/retired. 
###                         Valid values are: 
###                             0 - no deletes of any kind (default)
###                             1 - records can be deleted
###                             arrayref containing two strings - records can be 
###                                 retired but not deleted, by setting the given 
###                                 column to the specified value, e.g.
###                                 ['status', 'dead']

### IMPORTANT - children of this class _must_ be put in the EnsEMBL::ORM namespace,
### even if they are in a different plugin, as the CRUD framework relies on being able
### to automatically configure itself based solely on the URL

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Root);

sub new {
  my ($class, $model) = @_;
  return unless ref($model->object) =~ /Data::Rose/;

  ## Show all columns by default
  ## FIXME - relational columns are not currently included by default, because 
  ## doing this (using EnsEMBL::ORM::Rose::Column) breaks Rose::DB::Object::Metadata 
  ## for reasons I don't currently understand! If the object has relationships
  ## that you want to show on the form, you _must_ manually set the show_fields
  ## parameter in your child class 
  my $all_columns = [];
  foreach my $column (@{$model->object->get_table_columns}) {
    push @$all_columns, $column->name; 
  } 

  my $self = {
    'hub'                    => $model->hub,
    'show_fields'            => $all_columns,
    'record_table_columns'   => [],
    'record_select_columns'  => [],
    'record_select_query'    => {},
    'record_select_style'    => 'select',
    'pagination'             => 0,
    'show_preview'           => 1,
    'show_primary_key'       => 0,
    'show_tracking'          => 0,
    'permit_delete'            => 0,
  };

  bless $self, $class;

  $self->init($model->object);

  return $self;
}

##----------- ACCESSORS ----------------------------------------

sub hub { my $self = shift; return $self->{'hub'}; }

sub show_fields { my $self = shift; return $self->{'show_fields'}; }

sub record_select_query { my $self = shift; return $self->{'record_select_query'}; }

sub record_select_style { my $self = shift; return $self->{'record_select_style'}; }

sub record_select_columns { my $self = shift; return $self->{'record_select_columns'}; }

sub record_table_columns { my $self = shift; return $self->{'record_table_columns'}; }

sub pagination { my $self = shift; return $self->{'pagination'}; }

sub show_preview { my $self = shift; return $self->{'show_preview'}; }

sub show_primary_key { my $self = shift; return $self->{'show_primary_key'}; }

sub show_tracking { my $self = shift; return $self->{'show_tracking'}; }

sub permit_delete { my $self = shift; return $self->{'permit_delete'}; }

##-------------- Stubs for optional subclass methods -------------------

sub init {
### Override this stub in your child class to set any of the above variables
}

sub modify_form {
### This stub can be overridden in child classes, where it will be used
### to modify individual form elements, e.g. setting default values and
### 'required' flags, and customising labels (which default to the name 
### of the table column).
### Takes a reference to a hash of key-hashref pairs, where the keys are 
### names of fields and the hashref defines form element parameters such 
### as type and label (i.e. the arguments of the corresponding 
### EnsEMBL::Web::Form::Element module)
}

1;
