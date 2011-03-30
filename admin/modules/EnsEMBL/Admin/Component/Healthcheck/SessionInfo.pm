package EnsEMBL::Admin::Component::Healthcheck::SessionInfo;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);
use EnsEMBL::Web::Document::HTML::TwoColTable;

sub caption {
  return 'Healthcheck session summary';
}

sub content {
  my $self = shift;

  my $object    = $self->object;
  my $session   = $object->rose_object;
  my $release   = $object->requested_release;
  my $reports   = $object->rose_objects('reports');
  my $dropdown  = sprintf ('<form action="" method="get"><label><b>Go to other release: </b></label>%s&nbsp;<input type="submit" value="Go" /></form>', $self->render_all_releases_selectbox);

  return $self->no_healthcheck_found.$dropdown unless $session;

  my $start_time  = undef;
  my $end_time    = undef;
  eval {
    $start_time   = $self->hc_format_date($reports->[0]->timestamp) || '';
    $end_time     = $self->hc_format_date($reports->[1]->timestamp) || '';
  };
                        
  my $testcase_names = {};
  
  for (split ',', $session->config) {

    $_ =~ m/^([^:]+):(.+)$/;
    $testcase_names->{$1} ||= [];
    push @{$testcase_names->{$1}}, $2;
  }

  my $testgroups = '<ul>';
  $testgroups   .= sprintf('<li><i>%s</i> run on DB <b>%s</b></li>', join('</i>, <i>', @{$testcase_names->{$_}}), $_) for keys %$testcase_names;
  $testgroups   .= '</ul>';

  my $table      = EnsEMBL::Web::Document::HTML::TwoColTable->new;
  my $run_time   = defined $start_time && defined $end_time ? "<ul><li>Started: $start_time</li><li>Ended: $end_time</li></ul>" : " <i>(running time not known)</i>";

  $table->add_row("Last session:", $session->session_id.$run_time);
  $table->add_row("Host:", $session->host || '');
  $table->add_row("Testgroups:", $testgroups);

  return $table->render.$dropdown;
}

1;
