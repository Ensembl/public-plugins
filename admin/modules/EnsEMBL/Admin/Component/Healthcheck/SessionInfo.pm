=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Component::Healthcheck::SessionInfo;

use strict;

use parent qw(EnsEMBL::Admin::Component::Healthcheck);

sub caption {
  return 'Healthcheck session summary';
}

sub content {
  my $self = shift;

  my $object    = $self->object;
  my $session   = $object->rose_object;
  my $release   = $object->requested_release;

  my $form      = $self->get_all_releases_dropdown_form('Go to other release', 'release');

  return $self->no_healthcheck_found.$form->render unless $session;
  
  my $start_time  = $self->hc_format_date($session->start_time) || '';
  my $end_time    = $self->hc_format_date($session->end_time) || '';

  my $testcases   = {};
  $_ =~ m/^([^:]+):(.+)$/ and push @{$testcases->{$1} ||= []}, $2 for split ',', $session->config;

  # post e77 patch - format of config field is changed
  if (!keys %$testcases) {
    my ($groups, $db_list) = split ' ', $session->config;
    $groups = [ split /;/, $groups ];
    $testcases->{$_} = $groups for split /;/, $db_list;
  }

  my $table = $self->new_twocol(
    ['Last session:' => $session->session_id.($start_time && $end_time ? "<ul><li>Started: $start_time</li><li>Ended: $end_time</li></ul>" : " <i>(running time not known)</i>")],
    ['Host:'         => $session->host ? join '', '<ul>', (map {sprintf('<li>%s</li>', $_)} split(',', $session->host)), '</ul>' : '<i>not known</i>'],
    ['Testgroups:'   => join '', '<ul>', (map {sprintf('<li><i>%s</i> run on DB <b>%s</b></li>', join('</i>, <i>', @{$testcases->{$_}}), $_)} keys %$testcases), '</ul>']
  );

  return $table->render.$form->render;
}

1;
