package EnsEMBL::Admin::Component::Production::AnalysisWebData;

use strict;

use base qw(EnsEMBL::Admin::Component::Production);

sub caption {
  return '';
}

sub content {
  my $self = shift;
  
  my $object  = $self->object;
  my $dom     = $self->dom;
  my $records = $object->rose_objects;

  my $content = $dom->create_element('div',   {'class' => '_tabselector'});
  my $buttons = $content->append_child('div', {'class' => 'ts-buttons-wrap'});
  my $tabs    = $content->append_child('div', {'class' => 'spinner ts-spinner _ts_loading'});

  my $groups  = {};

  foreach my $record (@$records) {
    foreach my $groupby (qw(web_data_id analysis_description_id species_id db_type)) {
      my $val = $record->$groupby;
      push @{$groups->{$groupby}{$_} ||= []}, $record for ref $val eq 'ARRAY' ? @$val : $val;
    }
  }

  foreach my $key (sort keys %$groups) {

    (my $method = $key) =~ s/_id$//;
    my $group_title = join ' ', map {(ucfirst $_)} split '_', $method;

    $buttons->append_child('a', {'class' => '_ts_button ts-button', 'href' => "#$method", 'inner_HTML' => $group_title});
    $tabs->append_child('div', {
      'class'    => '_ts_tab ts-tab',
      'children' => [
        map {{
          'node_name'   => 'div',
          'class'       => 'prod-group',
          'inner_HTML'  => sprintf('%s (<a href="%s">%d records</a>)', $self->get_printable($groups->{$key}{$_}[0]->$method, $_), $self->hub->url({'action' => 'LogicName', 'gp', $key, 'id', $_}), scalar @{$groups->{$key}{$_}})
        }} sort keys %{$groups->{$key}}
      ]
    });
  }

  return $content->render;
}

1;