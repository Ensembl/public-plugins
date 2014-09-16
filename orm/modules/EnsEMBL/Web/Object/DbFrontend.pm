=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::DbFrontend;

### NAME: EnsEMBL::Web::Object::DbFrontend
### Base Object class for Web::Object drived classes that intend to use generic CRUD interface, DbFrontend.
### Extended from E::W::Object (plugged version for ORM) to add some CRUD configurations and methods to be used by DbFrontend components.

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Object);

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

  my $id = $self->hub->param('id') or return;

  $self->rose_objects($self->manager_class->fetch_by_primary_key($id, $self->_get_with_objects_params('Input')));
}

sub fetch_for_duplicate {
  ## Fetchs and saves rose objects to be displayed on 'Input' page (duplicate page), after ignoring the primary key
  ## If 'id' provided, gets the object with id, otherwise undef
  my $self = shift;
  
  return unless $self->permit_duplicate;

  my $id     = $self->hub->param('id') or return;
  my $record = $self->manager_class->fetch_by_primary_key($id, $self->_get_with_objects_params('Input'));
  $record    = $record->clone_and_reset if $record;

  $self->rose_objects($record);
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
  my $manager = $self->manager_class;

  $params               ||= {};
  $params->{'sort_by'}  ||= $self->get_sort_by_column;

  $self->rose_objects($manager->get_objects(%$params));
}

sub fetch_for_problem {
  ## Dummy method to ignore fetching anything from db for problem page
}

sub fetch_for_confirm {
  ## Fetches the requried object to be deleted/retired from the database
  my $self = shift;

  my $id = $self->hub->param('id') or return;

  $self->rose_objects($self->manager_class->fetch_by_primary_key($id));
}

sub fetch_for_delete {
  ## Fetches the requried object to be deleted/retired from the database
  ## Since deleting is done with rose object's method delete(cascade => 1), any related object fetched in this method along with the actual object will also be deleted
  ## So override this method to provide extra hashref with key 'with_objects' to fetch_by_primary_key method if cascade deletion is required
  shift->fetch_for_confirm;
}

sub _fetch_all {
  ## Private method, to fetch all the records for given params and page type
  my ($self, $page, $params) = @_;

  $params   ||= {};
  my $manager = $self->manager_class;

  my @ids = $self->hub->param('id') || ();
  scalar @ids == 1 and @ids = split ',', $ids[0];
  if (@ids) {
    $self->rose_objects($manager->fetch_by_primary_keys([@ids], $self->_get_with_objects_params($page, $params)));
  }
  else {
    $params->{'sort_by'} ||= $self->get_sort_by_column;
    $self->rose_objects($manager->fetch_by_page($self->pagination, $self->get_page_number, $self->_get_with_objects_params($page, $params)));
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
  ## @param Object type - Only needed if type different than default manager class
  my $self = shift;
  return @_ ? $self->SUPER::create_empty_object(@_) : $self->manager_class->create_empty_object;
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

sub get_fields {
  ## Gets all the fields according to show_fields and show_trackable_fields
  my $self = shift;

  unless (exists $self->{'_dbf_show_fields'}) {

    $self->{'_dbf_show_fields'} = $self->show_fields;
    
    if ($self->manager_class->object_class->meta->trackable) {

      my $t_fields    = $self->show_trackable_fields;
      my $field_names = [keys %{{@{$self->{'_dbf_show_fields'}}}}];
      $t_fields       = {'created' => $t_fields, 'modified' => $t_fields} unless ref $t_fields eq 'HASH';

      if (exists $t_fields->{'created'}) {
        $t_fields->{'created'} eq 'never' or grep {$_ eq 'created_by_user'} @$field_names or push @{$self->{'_dbf_show_fields'}}, (
          created_by_user   => {
            'type'      => 'noedit',
            'label'     => 'Created by',
            'display'   => $t_fields->{'created'}
          }
        );
        $t_fields->{'created'} eq 'never' or grep {$_ eq 'created_at'} @$field_names or push @{$self->{'_dbf_show_fields'}}, (
          created_at        => {
            'type'      => 'noedit',
            'label'     => 'Created at',
            'display'   => $t_fields->{'created'}
          }
        );
      }
      
      if (exists $t_fields->{'modified'}) {
        $t_fields->{'modified'} eq 'never' or grep {$_ eq 'modified_by_user'} @$field_names or push @{$self->{'_dbf_show_fields'}}, (
          modified_by_user  => {
            'type'      => 'noedit',
            'label'     => 'Modified by',
            'display'   => $t_fields->{'modified'}
          }
        );
        $t_fields->{'modified'} eq 'never' or grep {$_ eq 'modified_at'} @$field_names or push @{$self->{'_dbf_show_fields'}}, (
          modified_at       => {
            'type'      => 'noedit',
            'label'     => 'Modified at',
            'display'   => $t_fields->{'modified'}
          }
        );
      }
    }
  }

  return $self->deepcopy($self->{'_dbf_show_fields'});
}

sub is_trackable_field {
  my ($self, $rose_meta, $field_name) = @_;
  return $rose_meta->trackable && $field_name =~ /^(created|modified)_(at|by_user)$/ ? 1 : 0;
}

sub _get_with_objects_params {
  ## Constructs the extra query params that are to be passed to manager's get_objects to get the required objects for Display, List and Input pages
  ## @param page type - Display/Input/List
  ## @param Existing params if any
  my ($self, $page, $params) = @_;

  my $meta = $self->manager_class->object_class->meta;

  $params  ||= {};
  my $method = $page eq 'List' ? 'show_columns' : 'get_fields';

  my @relations   = map {$_->name} @{$meta->relationships};
  my %needed_cols = map {$_ => 1} (keys %{{@{$self->$method}}});

  if (@relations) {
    my @with_objects = grep $needed_cols{$_}, @relations;
    $params->{'with_objects'} = \@with_objects if @with_objects;
  }
  
  if ($meta->trackable) {
    my @with_users = grep $needed_cols{$_}, qw(created_by_user modified_by_user);
    $params->{'with_external_objects'} = \@with_users if @with_users;
  }
  
  return $params;
}

sub get_sort_by_column {
  ## Returns either title column name or primary column name depending upon the value of title column
  my $self    = shift;
  my $meta    = $self->manager_class->object_class->meta;
  my $column  = $meta->title_column;

  return $column && $meta->column($column) ? $column : $meta->primary_key_column_names->[0];
}

sub _populate_from_cgi {
  ## Private helper method used to set the values of different columns of the rose object from cgi parameters
  ## TODO - external relationships
  my $self        = shift;
  my $hub         = $self->hub;
  my @params      = $hub->param;
  my $rose_object = $self->rose_object;
  my $rose_meta   = $rose_object->meta;
  my $fields      = $self->get_fields;
  my $columns     = { map {$_->name => $_} $rose_meta->columns          };
  my $v_columns   = { map {$_->name => $_} $rose_meta->virtual_columns  };
  my $relations   = { map {$_->name => $_} $rose_meta->relationships    };
#   my $ext_rels    = { map {$_->name => $_} $rose_meta->external_relationships };
  my %field_names = map {$_ => 1} keys %{{@$fields}};
  my %param_names = map {$_ => 1} @params;

  delete $field_names{$_} for ('id', $rose_meta->primary_key_column_names->[0]);

  foreach my $field_name (keys %field_names) {
    next unless exists $param_names{$field_name};               # ignore if $field_name not present among the post params
    next if $self->is_trackable_field($rose_meta, $field_name); # dont get trackable info from CGI

    my $value     = [ $hub->param($field_name) ]; #CGI value
    my $relation  = $relations->{$field_name};
    my $column    = $columns->{$field_name};
    my $v_column  = $v_columns->{$field_name};
#     my $ext_rel   = $ext_rels->{$field_name};

    if ($column || $v_column) {
      if ($column && $column->type eq 'set') {
        my %allowed_values = map { $_ => 1 } @{$column->values};
        $value = [ grep $allowed_values{$_}, @$value ]; # validate the values
      } else {
        $value = shift @$value;
        $value = undef if $column && !$column->not_null && $value eq ''; # if column value can be NULL, set NULL value instead of an empty string
      }
      $rose_object->column_value($field_name, $value);

    } elsif ($relation) {
      $rose_object->relationship_value($relation, $value);

#     } elsif ($ext_rel) {
#       $rose_object->external_relationship_value($ext_rel, $value);

    }
  }
}


###############################################
############# Configuration stuff #############
###############################################

### show_fields             ArrayRef as [column names => {'label' => ? , 'type' => ?, etc}] that are displayed as form fields while adding/editing/viewing the data
###                         Purpose of arrayref instead of hashref is to maintain order
###                         Fields can include name of any relationship or 'external relationships' (as relationships are also treated as columns)
###                         HashRef for each column name can contain keys as accepted by E::W::Form::Fieldset->add_field method
###                         Following extra key are also accepted:
###                         'is_null' can be set true (or equal to the caption of the null option) in case type is dropdown.
###                         'display' can contain values 'never' or 'optional' - never will not display this field while viewing data (Display page); optional will ignore this in Display page if value is null
### show_trackable_fields   Tells whether or not to display trackable fields while adding/editing/viewing the data (only works for Trackable rose objects)
###                         Can return string values 'always', 'optional', or 'never' OR a hashref with keys 'modified', 'trackable' with values of keys as 'always', 'never' (default), 'optional'
### show_columns            ArrayRef as [column_name => label] or [column_name => {title => ?, class => ?, readonly => ?, width => ?, ensembl_object => ?}] that are displayed when records are displayed in tabular form (List page)
###                         Purpose of arrayref instead of hashref is to maintain order
###                         Column_name can include name of any relationship (as relationships are also treated as columns)
###                         Key 'ensembl_object' is used in case of relationship only, if a link to view the related object is to be displayed - is ignored in '... to many' relationships
### record_select_style     Specifies the style of form element that will be displayed to select a record to edit
###                         Select box by default, if set to 'radio', then radio buttons
### list_is_datatable       Flag to tell whether or not use jQuery dataTable for the List page
###                         Default true
### pagination              Number of records that are to be displayed per page when show in a list List and Display page
###                         Defaults to showing all records. If 0, undef or false - all records are shown
### show_preview            Flag to tell whether a preview should be displayed before record is updated/added
###                         Defaults to displaying the preview always
### permit_delete           Tells whether deleting the record is allowed or not
###                         'delete' means deleting is allowed
###                         'retire' means set the value of 'inactive_flag_column' to 'inactive_flag_value'
###                         Defaults to not allowing deletion
### permit_duplicate        Tells whether duplicating a record is allowed or not
### content_css             Css class name to go to the container of content - override this to customise styles
### record_name             HashRef telling the name of the record {'singular' => ? , 'plural' => } 
###                         Defaults to 'records'
### show_user_email         Shows user with mailto link for List and Display page
### use_ajax                Flag to tell whether or not to use AJAX for modification

### Configuration methods - Override the required ones in child class
sub show_fields           { return []; }
sub show_trackable_fields { return {qw(created always modified optional)}; }
sub show_columns          { return []; }
sub record_select_style   { ''; }
sub list_is_datatable     { 1;  }
sub pagination            { 0;  }
sub show_preview          { 1;  }
sub permit_delete         { 'retire'; }
sub permit_duplicate      { 1; }
sub content_css           { return 'dbf-content'; }
sub record_name           { return {qw(singular record plural records)}; }
sub show_user_email       { 1; }
sub use_ajax              { 1; }

1;
