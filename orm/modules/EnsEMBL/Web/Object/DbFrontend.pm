package EnsEMBL::Web::Object::DbFrontend;

### NAME: EnsEMBL::Web::Object::DbFrontend
### Base Object class for Web::Object drived classes that intend to use generic CRUD interface, DbFrontend.
### Extended from E::W::Object (plugged version for ORM) to add some CRUD configurations and methods to be used by DbFrontend components.

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Manager;

use base qw(EnsEMBL::Web::Object);

sub manager_class {
  ## IMPORTANT: Necessary to override
  ## Returns the default manager class that will be used for all db mining/manipulations
  warn "Manager class is not configured";
  return;
}

sub default_action {
  ## @returns the default action string for the webpages
  ## Override in child classes if another action needed as default
  return 'Display';
}

sub new {
  my $self = shift->SUPER::new(@_);

  return unless $self->manager_class;

  my $hub     = $self->hub;
  my $method  = lc "fetch_for_".($self->action || $self->default_action);

  ($self->can($method) or $method = lc "fetch_for_".$self->default_action and $self->can($method)) and $self->$method;
  return $self;
}

sub is_ajax_request {
  ## Tells whether or not the request was sent by ajaxy frontend
  my $self = shift;
  return $self->{'_is_ajax'} ||= $self->hub->param('_ajax') ? $self->hub->param('_list') ? 'list' : 1 : 0;
}

### Data fetching - rose_objects population from db
### Override the required one to customize the data available for viewing 

sub fetch_for_display {
  ## Fetchs and saves rose objects to be displayed on 'Display' page
  ## If 'id' provided, gets the object with id, otherwise gets all the rows wrt pagination
  ## @param A hashref of extra parameters to be added to rose manager's get_objects method
  shift->_fetch_all('Display', @_);
}

sub fetch_for_list {
  ## Fetchs and saves rose objects to be displayed on 'List' page (table view)
  ## @param A hashref of extra parameters to be added to rose manager's get_objects method
  shift->_fetch_all('List', @_);
}

sub fetch_for_add {
  ## Fetchs and saves rose objects to be displayed on 'Input' page (add page)
  my $self = shift;

  $self->rose_objects($self->create_empty_object);
}

sub fetch_for_edit {
  ## Fetchs and saves rose objects to be displayed on 'Input' page (edit page)
  ## If 'id' provided, gets the object with id, otherwise undef
  my $self = shift;

  my $id = $self->hub->param('id');
  return unless $id;

  $self->rose_objects($self->manager_class->fetch_by_primary_key($id, $self->_get_with_objects_params('Input')));
}

sub fetch_for_save {
  ## Fetchs and modifies the rose object, ready to be saved
  ## If 'id' provided, gets the object with id, otherwise undef
  my $self = shift;

  $self->fetch_for_edit;
  my $rose_object = $self->rose_object || $self->rose_objects($self->create_empty_object);
  
  $self->_populate_from_cgi;
}

sub fetch_for_preview {
  shift->fetch_for_save;
}

sub fetch_for_select {
  ## Fetchs and saves rose objects to be displayed on 'Select/Edit' page (dropdown/radio buttons view)
  ## @param A hashref of extra parameters to be added to rose manager's get_objects method
  my ($self, $params) = @_;
  
  $params ||= {};
  $params->{'sort_by'} ||= $self->manager_class->object_class->TITLE_COLUMN || $self->manager_class->object_class->primary_key;

  $self->rose_objects($self->manager_class->get_objects(%$params));
}

sub _fetch_all {
  ## Private method, to fetch all the records for given params and page type
  my ($self, $page, $params) = @_;
  
  $params ||= {};

  my @ids = $self->hub->param('id') || ();
  scalar @ids == 1 and @ids = split ',', $ids[0];
  if (@ids) {
    $self->rose_objects($self->manager_class->fetch_by_primary_keys([@ids], $self->_get_with_objects_params($page, $params)));
  }
  else {
    !$params->{'sort_by'} and $self->manager_class->object_class->TITLE_COLUMN and $params->{'sort_by'} = $self->manager_class->object_class->TITLE_COLUMN;
    $self->rose_objects($self->manager_class->fetch_by_page($self->pagination, $self->get_page_number, $self->_get_with_objects_params($page, $params)));
  }
}

sub get_page_number {
  ## Gets the page number in case of pagination
  ## @return int
  my $self  = shift;
  my $hub   = $self->hub;
  return $hub->param('id') ? undef : $hub->param('page') || 1;
}

sub get_page_count {
  ## Gets the total number of pages as per pagination config
  ## @param Extra Hashref to go to manager's count method as arg
  ## @return int
  my $self  = shift;
  my $total = $self->get_count(@_);
  my $shown = $self->pagination;
  
  return 1 unless $shown;
  
  return int($total / $shown) + !!($total % $shown);
}

sub get_count {
  ## Gets total number of records
  ## @params Extra Hashref that goes to manager's count method as arg
  my $self = shift;
  
  return $self->{'_rose_objects_count'} ||= $self->manager_class->count(@_);
}

sub create_empty_object {
  ## Wrapper around the default manager's create_empty_object method
  
  return shift->manager_class->create_empty_object;
}

sub delete {
  ## @overrides
  ## Deletes or retires the record according to the configuration
  my $self   = shift;
  my $method = $self->permit_delete;
  
  return unless $method =~ /^(delete|retire)$/;

  $method = "SUPER::$method";
  return $self->$method;
}

sub retire {
  ## @overrides
  ## Alias of delete
  return shift->delete;
}

sub _get_with_objects_params {
  ## Constructs the extra query params that are to be passed to manager's get_objects to get the required objects for Display, List and Input pages
  ## @param page type - Display/Input/List
  ## @param Existing params if any
  my ($self, $page, $params) = @_;

  $params  ||= {};
  my $method = $page eq 'List' ? 'show_columns' : 'show_fields';

  my $relations   = [ map {$_->name} @{$self->manager_class->get_relationships($self->rose_object)} ];
  my $needed_cols = { map {$_ => 1} (keys %{{@{$self->$method}}}) };

  if (@$relations) {
    my $with_objects = [];
    exists $needed_cols->{$_} and push @$with_objects, $_ for @$relations;
    $params->{'with_objects'} = $with_objects if @$with_objects;
  }
  
  if ($self->manager_class->is_trackable) {
    my $with_users = [];
    exists $needed_cols->{$_.'_user'} and push @$with_users, $_ for qw(created_by modified_by);
    $params->{'with_users'} = $with_users if @$with_users;
  }
  
  return $params;
}

sub _populate_from_cgi {
  ## Private helper method used to set the values of different columns of the rose object from cgi parameters
  my $self    = shift;
  my $hub     = $self->hub;
  my @params  = $hub->param;

  my $rose_object = $self->rose_object;

  my $fields    = $self->show_fields;
  my $columns   = { map {$_->name => $_} @{$self->manager_class->get_columns($rose_object)} };
  my $relations = { map {$_->name => $_} @{$self->manager_class->get_relationships($rose_object)} };
  
  my %field_names = map {$_ => 1} keys %{{@$fields}};
  my %param_names = map {$_ => 1} @params;
  
  delete $field_names{'id'};
  delete $field_names{$rose_object->primary_key};

  for (keys %field_names) {
  
    next unless exists $param_names{$_}; #ignore if variable not present among the post params
    next if $rose_object->is_trackable && $_ =~ /^(created|modified)_(by_user|at|by)$/; # dont get them from CGI

    my $value;
    my $type;

    if (exists $columns->{$_} && ($type = 'column') || exists $relations->{$_} && ($type = 'relation')) {
      if ($type eq 'relation' && $relations->{$_}->is_singular || $type eq 'column' && $columns->{$_}->type ne 'set') {
        $value = $self->hub->param($_);
      }
      else {
        my @val = $self->hub->param($_);
        $value  = { map {$_ => 1} @val };
        delete $value->{'0'} if $type eq 'relation';
        $value  = [ keys %$value ];
      }
    }
    $rose_object->$_($value);
  }
}


###############################################
############# Configuration stuff #############
###############################################

### show_fields             ArrayRef as [column names => {'label' => ? , 'type' => ?, etc}] that are displayed as form fields while adding/editing/viewing the data
###                         Purpose of arrayref instead of hashref is to maintain order
###                         Fields can include name of any relationship (as relationships are also treated as columns)
###                         HashRef for each column name can contain keys as accepted by E::W::Form::Fieldset->add_field method
###                         An extra key 'is_null' can be set true (or equal to the caption of the null option) in case type is dropdown. 
### show_columns            ArrayRef as [column names => labels] that are displayed when records are displayed in tabular form (List page)
###                         Purpose of arrayref instead of hashref is to maintain order
###                         Column_name can include name of any relationship (as relationships are also treated as columns)
### record_select_style     Specifies the style of form element that will be displayed to select a record to edit
###                         Select box by default, if set to 'radio', then radio buttons
### pagination              Number of records that are to be displayed per page when show in a list List and Display page
###                         Defaults to showing all records. If 0, undef or false - all records are shown
### show_preview            Flag to tell whether a preview should be displayed before record is updated/added
###                         Defaults to displaying the preview always
### permit_delete           Tells whether deleting the record is allowed or not
###                         'delete' means deleting is allowed
###                         'retire' means set the value of Rose::Object::INACTIVE_FLAG TO Rose::Object::INACTIVE_FLAG_VALUE
###                         Defaults to not allowing deletion
### content_css             Css class name to go to the container of content - override this to customise styles
### record_name             HashRef telling the name of the record {'singular' => ? , 'plural' => } 
###                         Defaults to 'records'
### show_user_email         Shows user with mailto link for List and Display page
### use_ajax                Flag to tell whether or not to use AJAX for modification

### Configuration methods - Override the required ones in child class
sub show_fields           { return []; }
sub show_columns          { return []; }
sub record_select_style   { ''; }
sub pagination            { 0;  }
sub show_preview          { 1;  }
sub permit_delete         { 'retire'; }
sub content_css           { return 'dbf-content'; }
sub record_name           { return {'singular' => 'record' , 'plural' => 'records'}; }
sub show_user_email       { 1; }
sub use_ajax              { 1; }

1;