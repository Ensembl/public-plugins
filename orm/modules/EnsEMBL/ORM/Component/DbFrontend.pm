package EnsEMBL::ORM::Component::DbFrontend;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::Form;
use EnsEMBL::Web::Data::User;
use Data::Dumper;

use base qw(EnsEMBL::Web::Component);

sub get_frontend_config {
### Instantiates the config module for this frontend
  my $self = shift;
  my ($module, $config);

  if ($self->model->hub->function) {
    $module = $self->model->hub->action;
  }
  else {
    $module = $self->model->hub->type;
  }
  my $class = "EnsEMBL::ORM::DbFrontend::$module";

  if ($self->dynamic_use($class)) {
    $config = $class->new($self->model);
  }
  return $config;
}

sub create_selection_form {
### Function to build a record selection form
  my ($self, $next) = @_;
  my $data = $self->model->object;
  return unless $data;

  my $hub = $self->hub;
  my $config = $self->get_frontend_config;

  my $form = $self->_create_form('select_record', $next);
  my $fieldset = $form->add_fieldset;
  my $style  = $config->record_select_style;

  my %param = (
    'type'    => 'DropDown',
    'select'  => $style,
    'name'    => 'id', 
  );

  my $options = [];
  if ($style eq 'select') {
    push @$options, {'name'=>'--- Choose ---', 'value'=>''};
  }
  my @records = @{$self->model->object->fetch_all};
  my $key = $self->model->object->primary_key;
  my $columns = $config->record_select_columns;
  foreach my $record (@records) {
    my $name;
    if (@$columns) {
      my @text;
      foreach my $col (@$columns) {
        push @text, $record->$col;
      }
      $name = join(' - ', @text);
    }
    else {
      warn "!!! NO COLUMNS DEFINED IN DBFRONTEND";
      $name = 'Record '.$record->$key;
    }
    push @$options, {'name' => $name, 'value' => $record->$key};
  }

  $param{'values'} = $options;

  $fieldset->add_element(%param);

  $form->add_button('type' => 'Submit', 'name' => 'submit', 'value' => $next);

  return $form;
}

sub create_input_form {
### Function to build a record editing form
  my ($self, $form_type, $record) = @_;
  my $data = $self->model->object;
  return unless $data;

  my $hub = $self->hub;
  my $config = $self->get_frontend_config;
  my $next = $config->show_preview ? 'Preview' : 'Save';
  my $form = $self->_create_form($form_type, $next);
  my $fieldset = $form->add_fieldset;

  ## Get field definitions from database columns
  my $param = $self->_unpack_db_table;

  ## Customise fields
  $config->modify_form($param, 'input');

  ## Add desired fields as form elements
  my @fields = ($self->model->object->primary_key);
  push @fields, @{$config->show_fields}; 
  if ($config->show_tracking && $form_type ne 'Add') {
    push @fields, (qw(created_by created_at modified_by modified_at));
  }
  foreach my $name (@fields) {
    my $p = $param->{$name};
    if ($record) {
      if ($name eq 'created_by' || $name eq 'modified_by') {
        ## Format 'tracking' fields nicely
        $p->{'value'} = $self->_get_user_name($record->$name);
        if ($name eq 'created_by' && $record->created_by) {
          $form->add_element('type' => 'Hidden', 'name' => 'created_by',
              'value' => $record->created_by);
        }
      }
      elsif ($name eq 'created_at' || $name eq 'modified_at') {
        $p->{'value'} = $self->_get_pretty_date($record->$name);
        if ($name eq 'created_at' && $record->created_at) {
          $form->add_element('type' => 'Hidden', 'name' => 'created_at',
              'value' => $record->created_at);
        }
      }
      else {
        $p->{'value'} = $record->$name;
      }
    }
    if ($p->{'is_primary_key'}) {
      if ($config->show_primary_key) {
        $fieldset->add_element(%$p);
      }
      if ($form_type ne 'Add') {
        ## Make sure to pass the primary key!!
        $p->{'type'} = 'Hidden';
        $fieldset->add_element(%$p);
      }
    }
    else {
      $fieldset->add_element(%$p);
    }
  }
  $form->add_element('type' => 'Hidden', 'name' => 'form_type', 'value' => $form_type);
  $form->add_button('type' => 'Submit', 'name' => 'submit', 'value' => $next);

  return $form;
}

sub create_preview_form {
### Function to build a record preview form
  my $self = shift;
  return unless $self->model->object;

  my $hub = $self->hub;
  my $config = $self->get_frontend_config;

  my $form = $self->_create_form('Preview', 'Save');
  my $fieldset = $form->add_fieldset;

  ## Get field definitions from database columns
  my $param = $self->_unpack_db_table('noedit');

  ## Customise fields
  $config->modify_form($param, 'input');

  $self->_add_preview_widgets(
    'fieldset'  => $fieldset,
    'param'     => $param,
    'config'    => $config,
    'previous'  => $hub->param('form_type'),
  );
  $form->add_button('type' => 'Submit', 'name' => 'submit', 'value' => 'Save');
  return $form;
}

sub _add_preview_widgets {
  my ($self, %args) = @_;
  my $hub = $self->hub;

  ## Add desired fields as form elements
  my @fields;
  ## Force inclusion of primary key, as we need this for hidden form
  unless ($args{'config'}->show_primary_key) {
    push @fields, $self->model->object->primary_key;
  }
  ## Add normal viewable fields
  push @fields, @{$args{'config'}->show_fields};
  ## Add tracking if needed 
  if ($args{'config'}->show_tracking) {
    push @fields, (qw(created_by created_at modified_by modified_at));
  }
  my $fieldset = $args{'fieldset'};

  foreach my $name (@fields) {
    my $p = $args{'param'}{$name};

    if ($name ne $self->model->object->primary_key || $args{'config'}->show_primary_key) {
      ## Populate from CGI parameters where available
      if ($hub->param($name)) {
        if ($name eq 'created_by') {
          $p->{'value'} = $self->_get_user_name($hub->param($name));
        }
        elsif ($name eq 'created_at') {
          $p->{'value'} = $self->_get_pretty_date($hub->param($name));
        }
        elsif ($p->{'values'}) {
          my (%lookup, @v_names);
          my @V = ($hub->param($name));
          foreach my $value (@{$p->{'values'}}) {
            if (ref($value) eq 'HASH') {
              $lookup{$value->{'value'}} = $value->{'name'};
            }
            else {
              $lookup{$value} = $value;
            }
          }
          foreach my $v (@V) {
            push @v_names, $lookup{$v};
          }
          $p->{'value'} = join(', ', @v_names);
        }
        else {
          $p->{'value'} = $hub->param($name);
        }
      }
      elsif ($args{'previous'} eq 'Edit') {
        ## Modified_ fields are a special case, since they are always 
        ## updated on edit
        if ($name eq 'modified_by') {
          $p->{'value'} = $self->_get_user_name($hub->user->id);
        }
        elsif ($name eq 'modified_at') {
          $p->{'value'} = 'now'; 
        }
      }
      $fieldset->add_element(%$p);
    }

    ## Also add everything as a hidden field (skipping 'tracking' timestamps)
    next if ($name eq 'created_at' || $name eq 'modified_at');
    next if ($name eq 'created_by' && $args{'previous'} ne 'Add');
    next if ($name eq 'modified_by' && $args{'previous'} eq 'Add');

    $p->{'type'} = 'Hidden';
    ## Deal with multi-value fields (e.g. dropdowns)
    my @values = ($hub->param($name));
    if (@values > 1) {
      foreach my $v (@values) {
        $p->{'value'} = $v;
        $fieldset->add_element(%$p);
      }
    }
    else {
      if ($name eq $self->model->object->primary_key) {
        ## Always pass the primary key if it exists
        $p->{'value'} = $hub->param($name);
      }
      elsif ($name eq 'created_by' || $name eq 'modified_by') {
        ## Manually set ID of logged-in user
        $p->{'value'} = $hub->user->id;
      }
      $fieldset->add_element(%$p);
    }
  }
}

sub _get_user_name {
  my ($self, $user_id) = @_;
  my $name = 'no-one';
        
  if ($user_id > 0) {
    my $user = EnsEMBL::Web::Data::User->new($user_id);
    $name = $user->name if $user;
  }
  return $name;
}

sub _get_pretty_date {
  my ($self, $date) = @_;
  if ($date =~ /^0000-/) {
    return '';
  }
  else {
    return $self->pretty_date($date, 'full');
  }
}

sub _unpack_db_table {
### "Unpacks" the columns of a database into a hash of hashes
### that can be used to produce form elements. Default is to
### fully populate parameters with input form options
  my ($self, $mode) = @_;
  my $param_set;
  my $data = $self->model->object;

  my @columns = @{$data->get_table_columns};
  push @columns, @{$data->get_related_columns};

  foreach my $column (@columns) {
    my $name = $column->name;
    my $param = {'name' => $name};
    my $data_type = $column->type;

    ## set label
    my $label = ucfirst($name);
    $label =~ s/_/ /g;
    $param->{'label'} = $label;

    if ($mode eq 'noedit') {
      $param->{'type'} = 'NoEdit';
      if ($data_type eq 'enum' || $data_type eq 'set') {
        ## Set 'values' on lookups, so we can do reverse lookup later
        my $values  = $column->values;
        if (ref($values->[0]) eq 'HASH') {
          $param->{'values'} = $values;
        }
        else {
          my $tmp;
          foreach my $v (@$values) {
            push @$tmp, {'name' => $v, 'value' => $v};
          }
          $param->{'values'} = $tmp;
        }
        $param->{'values'} = $column->values;
      }
    }
    else {
      if ($column->is_primary_key_member || $name =~ /^created_|^modified_/) {
        $param->{'type'} = 'NoEdit';
        $param->{'is_primary_key'} = 1 if $column->is_primary_key_member;
      }
      elsif ($name =~ /password/) {
        $param->{'type'} = 'Password';
      }
      elsif ($data_type eq 'integer') {
        $param->{'type'} = 'Int';
      }
      elsif ($data_type eq 'text') {
        $param->{'type'} = 'Text';
      }
      elsif ($data_type eq 'enum' || $data_type eq 'set') {
        $param->{'select'}  = 'select';
        if ($data_type eq 'enum') {
          ## Use radio buttons if only three options
          my $values = $column->values;
          if (@$values < 4) {
            $param->{'select'} = 'radio';
          }
          $param->{'type'} = 'DropDown';
        }
        else {
          $param->{'type'} = 'MultiSelect';
        }
        my $values  = $column->values;
        if (ref($values->[0]) eq 'HASH') {
          $param->{'values'} = $values;
        }
        else {
          my $tmp;
          foreach my $v (@$values) {
            push @$tmp, {'name' => $v, 'value' => $v};
          }
          $param->{'values'} = $tmp;
        }
      }
      else {
        $param->{'type'} = 'String';
        if ($data_type eq 'varchar') {
          $param->{'maxlength'} = $column->length;
        }
      }
    }
    $param_set->{$name} = $param;
  }

  return $param_set;
}

sub _create_form {
  my ($self, $current, $next) = @_;
  my $hub = $self->hub;

  my $url = '/'.$hub->species_defs->species_path;
  $url = '' if $url !~ /_/;
  $url .= '/'.$hub->type.'/'.$next;

  my $form = EnsEMBL::Web::Form->new($current, $url, 'post');
  $form->add_attribute('class', 'narrow-labels');
  return $form;
}

1;
