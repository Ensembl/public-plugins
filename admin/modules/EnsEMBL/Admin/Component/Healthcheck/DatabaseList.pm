package EnsEMBL::Admin::Component::Healthcheck::DatabaseList;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

sub caption {
  return 'Database List';
}

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $release = $object->current_release;

  my $session_reports = $object->rose_objects('session_reports');
  my $release_reports = $object->rose_objects('release_reports');

  my $hc_this_session = { map { $_->database_name => 1 } @$session_reports };
  my $hc_this_release = { map { $_->database_name => 1 } @$release_reports };

  my $text_class      = ['hc-notdone', '', 'hc-releaseonly', 'hc-done'];
  my $html            = qq(<div class="_hc_infobox tinted-box"><p><b>Colour coding:</b></p><ul>
                          <li class="hc-done">Databases being healthchecked.</li>
                          <li class="hc-notdone">Databases not being healthchecked.</li>
                          <li class="hc-releaseonly">Databases healthchecked in currect release but not in last session.</li></ul>
                        </div>);

  my $table           = $self->new_table([
    {'key' => 'db_name', 'title' => 'Database Name', 'sort' => 'html'},
    {'key' => 'species', 'title' => 'Species'},
    {'key' => 'type',    'title' => 'DB Type'},
    {'key' => 'server',  'title' => 'Server'},
  ], [], {'data_table' => 1});

  my $db_list         = $object->get_database_list;

  for (sort keys %$db_list) {

    my $hc_status = int ((1 * exists $hc_this_session->{$_}) + (2 * exists $hc_this_release->{$_})) || 0;

    $table->add_row({
      'db_name' => $hc_status > 2
        ? $self->get_healthcheck_link({ 'type' => 'database_name', 'param' => $_, 'release' => $release, 'class' => $text_class->[ $hc_status ]})
        : sprintf('<span class="%s">%s</span>', $text_class->[ $hc_status ], $_),
      'species' => $db_list->{$_}->{'species'},
      'type'    => $db_list->{$_}->{'type'},
      'server'  => $db_list->{$_}->{'server'}
    });
  }

  return $html.$table->render;
}

1;