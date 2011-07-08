package EnsEMBL::Admin::Component::Healthcheck::SessionInfo;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

sub caption {
  return 'Healthcheck session summary';
}

sub content {
  my $self = shift;

  my $object    = $self->object;
  my $session   = $object->rose_object;
  my $release   = $object->requested_release;
  my $dropdown  = sprintf('<form action="" method="get"><label><b>Go to other release: </b></label>%s&nbsp;<input type="submit" value="Go" /></form>', $self->render_all_releases_selectbox);

  return $self->no_healthcheck_found.$dropdown unless $session;
  
  my $start_time  = $self->hc_format_date($session->start_time) || '';
  my $end_time    = $self->hc_format_date($session->end_time) || '';

  my $testcases   = {};
  $_ =~ m/^([^:]+):(.+)$/ and push @{$testcases->{$1} ||= []}, $2 for split ',', $session->config;
  
  my $data = [
    'Last session:' => $session->session_id.($start_time && $end_time ? "<ul><li>Started: $start_time</li><li>Ended: $end_time</li></ul>" : " <i>(running time not known)</i>"),
    'Host:'         => $session->host ? join '', '<ul>', (map {sprintf('<li>%s</li>', $_)} split(',', $session->host)), '</ul>' : '<i>not known</i>',
    'Testgroups:'   => join '', '<ul>', (map {sprintf('<li><i>%s</i> run on DB <b>%s</b></li>', join('</i>, <i>', @{$testcases->{$_}}), $_)} keys %$testcases), '</ul>'
  ];

  my $table = $self->dom->create_element('table');
  while (@$data) {
    $table->append_child('tr', {'children' => [
      {'node_name' => 'th', 'inner_HTML' => shift @$data},
      {'node_name' => 'td', 'inner_HTML' => shift @$data}
    ]});
  }

  return $table->render.$dropdown;
}

1;