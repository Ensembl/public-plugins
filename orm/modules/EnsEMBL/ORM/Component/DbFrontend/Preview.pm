package EnsEMBL::ORM::Component::DbFrontend::Preview;

### NAME: EnsEMBL::ORM::Component::DbFrontend::Preview
### Creates a page displaying a non-editable view of a record

### STATUS: Under development
### Note: This module should not be modified! 
### To customise an individual form, see (or create) the appropriate 
### EnsEMBL::ORM::DbFrontend module

### DESCRIPTION:

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub content {
### Builds a preview form, i.e. one that shows the user's input as non-editable
### fields and also creates hidden fields that are used to forward the input to
### the 'save' step.
  my $self = shift;

  my $hub = $self->hub;
  my $config = $self->get_frontend_config;

  my $form = $self->create_form('Save');
  my $fieldset = $form->add_fieldset;
  my $previous = $hub->param('form_type');

  ## Get field definitions from database columns
  my $param = $self->unpack_db_table('noedit');

  ## Customise fields
  $config->modify_form($param, 'input');

  ## Add desired fields as form elements
  my @fields;
  ## Force inclusion of primary key, as we need this for hidden form
  unless ($config->show_primary_key) {
    push @fields, $self->object->primary_key;
  }
  ## Add normal viewable fields
  push @fields, @{$config->show_fields};
  ## Add tracking if needed 
  if ($config->show_tracking) {
    push @fields, (qw(created_by created_at modified_by modified_at));
  }

  foreach my $name (@fields) {
    my $p = $param->{$name};

    if ($name ne $self->object->primary_key || $config->show_primary_key) {
      ## Populate from CGI parameters where available
      if ($hub->param($name)) {
        if ($name eq 'created_by') {
          $p->{'value'} = $self->get_user_name($hub->param($name));
        }
        elsif ($name eq 'created_at') {
          $p->{'value'} = $self->get_pretty_date($hub->param($name));
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
      elsif ($previous eq 'Edit') {
        ## Modified_ fields are a special case, since they are always 
        ## updated on edit
        if ($name eq 'modified_by') {
          $p->{'value'} = $self->get_user_name($hub->user->id);
        }
        elsif ($name eq 'modified_at') {
          $p->{'value'} = 'now';
        }
      }
      $fieldset->add_element(%$p);
    }

    ## Also add everything as a hidden field (skipping 'tracking' timestamps)
    next if ($name eq 'created_at' || $name eq 'modified_at');
    next if ($name eq 'created_by' && $previous ne 'Add');
    next if ($name eq 'modified_by' && $previous eq 'Add');

    $p->{'type'} = 'Hidden';
    ## Deal with multi-value fields (e.g. dropdowns)
    my @values = ($hub->param($name));
    if (@values > 1 || $name eq 'species') {
      #TODO - What if only one value is selected in a multiple select dropdown? - remove the hack $name eq 'species' (is applied for admin changelogs)
      foreach my $v (@values) {
        $p->{'value'} = $v;
        $fieldset->add_element(%$p);
      }
    }
    else {
      if ($name eq $self->object->primary_key) {
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

  $form->add_button('type' => 'Submit', 'name' => 'submit', 'value' => 'Save');

  return $form->render;
}

1;
