package EnsEMBL::ORM::Component::DbFrontend::Select;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::ORM::Component::DbFrontend);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return 'Select a Record';
}

sub content {
### Creates a simple form for selecting a record to edit or delete
### Returns HTML
  my $self = shift;
  my $html;

  my @records = @{$self->object->fetch_all};
  
  if (@records) {
    ## Display warnings if deleting!
    if ($self->hub->action eq 'SelectToDelete') {
      my $config = $self->get_frontend_config;
      my $permit_delete = $config->permit_delete;
      if ($permit_delete) {
        if (ref($permit_delete) eq 'ARRAY') {    ## 'retire' mode
          my $status = $permit_delete->[0];
          my $value  = $permit_delete->[1];
          $html .= $self->_info('Record deletion', "Please note that records are not deleted; instead their $status is set to $value.");
        }
        else {
          my $message = 'WARNING: You are about to permanently delete a record from the database!';
          if ($config->show_preview) {
            $message .= ' You will be given an opportunity to preview the record before deletion.';
          }
          $html .= $self->_warning('Record deletion', $message);
        }
      }
      else {
        $html .= $self->_info('Record deletion', 'Sorry, it is not permitted to delete records from this table.');
      }
    }

    my $data = $self->object;

    my $hub = $self->hub;
    my $config = $self->get_frontend_config;

    my ($next, $button_text);
    if ($hub->action eq 'SelectToDelete') {
      if ($config->{'show_preview'}) {
        $next = 'Preview';
      }
      else {
        $next = 'Delete';
      }
      $button_text = $next;
    }
    else {
      $next = 'Edit';
      $button_text = 'Next';
    }

    ## Create form
    my $form = $self->create_form($next);
    my $fieldset = $form->add_fieldset;
    my $style  = $config->record_select_style;

    ## Create dropdown element
    my %param = (
      'type'    => 'DropDown',
      'select'  => $style,
      'name'    => 'id',
    );

    my $options = [];
    if ($style eq 'select') {
      push @$options, {'name'=>'--- Choose ---', 'value'=>''};
    }
    my $key = $self->object->primary_key;
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

    $form->add_button('type' => 'Submit', 'name' => 'submit', 'value' => $button_text);

    $html .= $form->render;
  }
  else {
    $html .= '<p>No records found.</p>';
  }

  return $html;
}

1;
