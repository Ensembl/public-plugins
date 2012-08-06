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

  my $db_list = $object->get_database_list;
  
  my $text_class = ['hc-notdone', '', 'hc-releaseonly', 'hc-done'];
  my $html = qq(<div class="_hc_infobox tinted-box"><p><b>Colour coding:</b></p><ul>
                <li class="hc-done">Databases being healthchecked.</li>
                <li class="hc-notdone">Databases not being healthchecked.</li>
                <li class="hc-releaseonly">Databases healthchecked in currect release but not in last session.</li></ul>
  </div>);

  foreach my $server (sort keys %$db_list) {

    $html .= "<h3>Server: $server</h3>";
    foreach my $species (sort keys %{$db_list->{$server}}) {

      my $db_list     = [ sort @{$db_list->{$server}{$species}} ];
      my $db_stats    = {};
      $db_stats->{$_} = int ((1 * exists $hc_this_session->{$_}) + (2 * exists $hc_this_release->{$_})) for @$db_list;

      $html .= '<h4>'.ucfirst substr ($species, 1).'</h4><ul>';
      $html .= '<li class="'.$text_class->[$db_stats->{$_} || 0].'">'
                  .($db_stats->{$_} > 2 ? $self->get_healthcheck_link({ 'type' => 'database_name', 'param' => $_, 'release' => $release }) : $_)
                  .'</li>' for @$db_list;
      $html .= '</ul>';
    }
  }

  return $html;
}

1;