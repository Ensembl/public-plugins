=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

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