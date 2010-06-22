package EnsEMBL::Web::Component::DbFrontend;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::Form;

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
  my $class = "EnsEMBL::Web::DbFrontend::$module";

  if ($self->dynamic_use($class)) {
    $config = $class->new($self->model);
  }
  return $config;
}

sub create_input_form {
### Function to build a record editing form
  my ($self, $form_type) = @_;
  my $data = $self->model->object;
  return unless $data;

  my $hub = $self->hub;
  my $config = $self->get_frontend_config;
  my $next = $config->show_preview ? 'Preview' : 'Save';
  my $form = $self->_create_form($form_type, $next);
  my $fieldset = $form->add_fieldset;

  ## Get field definitions from database columns
  my $param = $self->_unpack_db_table($data);

  ## Customise fields
  $config->modify_form($param, 'input');

  ## Add desired fields as form elements
  my @fields = $config->show_fields; 
  foreach my $name (@fields) {
    my $p = $param->{$name};
    next if ($p->{'is_primary_key'} && !$config->show_primary_key);
    next if ($name =~ /^created_|^modified_/ && ($form_type ne 'Edit' || !$config->show_history));
    $fieldset->add_element(%$p);
  }
  $form->add_button('type' => 'Submit', 'name' => 'submit', 'value' => $next);

  return $form;
}

sub create_preview_form {
### Function to build a record preview form
  my $self = shift;
  my $data = $self->model->object;
  return unless $data;

  my $hub = $self->hub;
  my $config = $self->get_frontend_config;

  my $form = $self->_create_form('Preview', 'Save');
  my $fieldset = $form->add_fieldset;

  ## Get field definitions from database columns
  my $param = $self->_unpack_db_table($data, 'noedit');

  ## Customise fields
  $config->modify_form($param, 'input');

  ## Add desired fields as form elements
  my @fields = $config->show_fields; 
  foreach my $name (@fields) {
    my $p = $param->{$name};
    my @A = keys %$p;
    ## Populate from CGI parameters where available
    if ($hub->param($name)) {
      if ($p->{'values'}) {
        my %lookup;
        foreach my $hash (@{$p->{'value'}}) {
          $lookup{$hash->{'value'}} = $hash->{'name'};
        }
        warn ">>> $name VALUES";
        my @V = $hub->param($name);
        my @v_names;
        foreach my $v (@{$p->{'value'}}) {
          push @v_names, $lookup{$v};
        }
        $p->{'value'} = join(', ', @v_names);
      }
      else {
        $p->{'value'} = $hub->param($name);
      }
    }
    $fieldset->add_element(%$p);
    ## Also add everything as a hidden field
    $p->{'type'} = 'Hidden';
    $fieldset->add_element(%$p);
  }

  $form->add_button('type' => 'Submit', 'name' => 'submit', 'value' => 'Save');
  return $form;
}

sub _unpack_db_table {
### "Unpacks" the columns of a database into a hash of hashes
### that can be used to produce form elements. Default is to
### fully populate parameters with input form options
  my ($self, $data, $mode) = @_;
  my $param_set;

  my @columns = @{$data->get_all_columns};

  foreach my $column (@columns) {
    my $name = $column->name;
    my $param = {'name' => $name};
    my $data_type = $column->type;

    ## set label
    my $label = ucfirst($column->name);
    $label =~ s/_/ /g;
    $param->{'label'} = $label;

    if ($mode eq 'noedit') {
      $param->{'type'} = 'NoEdit';
      ## Set 'values' on lookups, so we can do reverse lookup later
      if ($data_type eq 'enum' || $data_type eq 'set') {
        my $values  = $column->values;
        if (ref($column) eq 'EnsEMBL::Data::DBSQL::Column') {
          $param->{'values'}  = $values;
        }
        else {
          my $value_hashes;
          foreach my $v (@$values) {
            push @$value_hashes, {'name' => $v, 'value' => $v};
          };
          $param->{'values'}  = $value_hashes;
        }
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
        if (ref($column) eq 'EnsEMBL::Data::DBSQL::Column') {
          $param->{'values'}  = $values;
        }
        else {
          my $value_hashes;
          foreach my $v (@$values) {
            push @$value_hashes, {'name' => $v, 'value' => $v};
          };
          $param->{'values'}  = $value_hashes;
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
