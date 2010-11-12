package EnsEMBL::Admin::Component::Healthcheck::DatabaseList;

use strict;

use DBI;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

use constant {
  SERVER    => 'ens-staging1 ens-staging2',
  DB_USER   => 'ensro',
  DB_PORT   => '3306',
};

sub caption {
  return 'Database List';
}

sub content {

  my $self          = shift;
  my $hub           = $self->hub;
  my $release       = $hub->species_defs->ENSEMBL_VERSION;
  my $db_interface  = $self->object;

  my $session_db_interface  = $db_interface->data_interface('Session');
  my $last_session          = $session_db_interface->fetch_last($release);
  my $last_session_id       = $last_session ? $last_session->session_id || 0 : 0;
  
  return 'No Healthcheck done in the current release.' unless $last_session_id;
  
  my $report_db_interface = $db_interface->data_interface('Report');
  
  my $hc_this_session = { map { $_->database_name => 1 } @{ $report_db_interface->fetch_for_distinct_databases($last_session_id)  || [] } };
  my $hc_this_release = { map { $_->database_name => 1 } @{ $report_db_interface->fetch_for_distinct_databases(undef, $release)   || [] } };

  my $drh = DBI->install_driver('mysql');
  my $dbs = {};
  
  #construct a data structure
  for my $server (split ' ', $self->SERVER) {
    $dbs->{ $server } = {};
    my $db_list       = [ $drh->func($server, $self->DB_PORT, $self->DB_USER, '_ListDBs') ];
    for (@$db_list) {
      my $species = '2others'; #'2' prefixed for sorting - '2' keeps 'others' at the end instead considering it alphabetically
      if ($_ =~ /_core|_otherfeatures|_cdna|_variation|_funcgen|_compara|_vega/) {
        $_ =~ /^([a-z]+_[a-z]+)/; #get species
        my $all_species = { map {$_ => 1} @{ $hub->species_defs->ENSEMBL_DATASETS || [] } }; #species validation
        $species = '1'.$1 if exists $all_species->{ ucfirst $1 }; #'1' prefixed for sorting -  keeps it always above 'others'
      }
      $dbs->{ $server }{ $species }       = {} unless exists $dbs->{ $server }{ $species };
      $dbs->{ $server }{ $species }{ $_ } = int ((1 * exists $hc_this_session->{ $_ }) + (2 * exists $hc_this_release->{ $_ }));
    }
  }
  
  #print the data structure
  my $text_class = ['hc-notdone', 'hc-done', 'hc-releaseonly', 'hc-done'];
  my $html = qq(<div class="hc-infobox"><p><b>Colour coding:</b></p><ul>
                <li class="hc-done">Databases being healthchecked.</li>
                <li class="hc-notdone">Databases not being healthchecked.</li>
                <li class="hc-releaseonly">Databases healthchecked in currect release but not in last session.</li></ul>
  </div>);
  foreach my $server (sort keys %$dbs) {
  
    $html .= "<h3>Server: $server</h3>";
    foreach my $species (sort keys %{ $dbs->{ $server } }) {
      $html .= '<h4>'.ucfirst substr ($species, 1).'</h4><ul>';
      $html .= '<li class="'.$text_class->[ $dbs->{ $server }{ $species }{ $_ } || 0].'">'
                  .($dbs->{ $server }{ $species }{ $_ } > 0 ? $self->get_healthcheck_link({ 'type' => 'database_name', 'param' => $_, 'release' => $release }) : $_)
                  .'</li>' for (sort keys %{ $dbs->{ $server }{ $species } });
      $html .= '</ul>';
    }
  }
  
  return $html;
}

1;
