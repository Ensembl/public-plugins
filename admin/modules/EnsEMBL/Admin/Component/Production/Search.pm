package EnsEMBL::Admin::Component::Production::Search;

use base qw(EnsEMBL::Admin::Component::Production);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $dom     = $self->dom;
  my $records = $self->object->rose_objects;
  my $groups  = {};
  my $form    = $self->new_form({
    'action'    => $hub->url({'action' => 'LogicName'}),
    'method'    => 'get',
    'dom'       => $dom
  });
  my $fieldset = $form->add_fieldset('Search analysis web data:');

  ## create a data structure of all the records
  foreach my $record (@$records) {
    foreach my $groupby (qw(web_data_id analysis_description_id species_id db_type)) {
      my $val = $record->$groupby;
      push @{$groups->{$groupby}{$_} ||= []}, $record for ref $val eq 'ARRAY' ? @$val : $val;
    }
  }

  ## Iterate through the data structure to populate the dropdown options
  foreach my $key (sort keys %$groups) {

    (my $method = $key) =~ s/_id$//;

    $fieldset->add_field({
      'label'   => join (' ', map {ucfirst $_} split '_', $method),
      'type'    => $method eq 'web_data' ? 'radiolist' : 'dropdown',
      'name'    => $key,
      'value'   => '',
      'values'  => [
        {'value' => '', 'caption' => {'inner_text' => 'Any'}},
        map {{
          'caption' => {'inner_HTML' => $key eq 'db_type' ? $_ : $self->get_printable($groups->{$key}{$_}[0]->$method), $method eq 'web_data' ? ('class' => $self->_JS_CLASS_DATASTRUCTURE) : ()},
          'value'   => ($_ || '0')
        }} sort keys %{$groups->{$key}}
      ],
    });
  }

  $fieldset->add_button({'value' => 'Apply filter'});

  return $dom->create_element('div', {'children' => [$form]})->render;
}

1;