package EnsEMBL::Admin::Component::Healthcheck::SessionInfo;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);
use EnsEMBL::Web::Document::HTML::TwoColTable;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  return 'Healthcheck session summary';
}

sub content {
  my $self = shift;

  my $hub                   = $self->hub;
  my $db_interface          = $self->object;
  my $release               = $hub->param('release') || $hub->species_defs->ENSEMBL_VERSION;
  
  my $previous  = $self->render_all_releases_selectbox($release);
  $previous     = qq(<form action="" method="get"><label><b>Go to other release: </b></label>$previous&nbsp;<input type="submit" value="Go" /></form>);

  return $self->NO_HEALTHCHECK_FOUND.$previous unless $self->validate_release($release);
                            
  my $session_db_interface  = $db_interface->data_interface('Session');
  my $last_session          = $session_db_interface->fetch_last($release);
  my $last_session_id       = $last_session ? $last_session->session_id || 0 : 0;
                            
  return $self->NO_HEALTHCHECK_FOUND.$previous unless $last_session_id;
                            
  my $report_db_interface   = $db_interface->data_interface('Report');
  my $start_time            = undef;
  my $end_time              = undef;
  eval {
    $start_time             = $self->hc_format_date($report_db_interface->fetch_first_for_session($last_session_id)->timestamp) || '';
    $end_time               = $self->hc_format_date($report_db_interface->fetch_last_for_session ($last_session_id)->timestamp) || '';
  };                        
                            
  my $testcase_names        = {};
  
  for (split ',', $last_session->config) {
  
    $_ =~ m/^([^:]+):(.+)$/;
    
    unless (exists $testcase_names->{ $1 }) {
      $testcase_names->{ $1 } = [];
    }
    push @{$testcase_names->{ $1 }}, $2;
  }
  
  my $testgroups_html = '<ul>';
  for (keys %$testcase_names) {
    $testgroups_html .= '<li><i>'.(join '</i>, <i>', @{$testcase_names->{ $_ }}).'</i> ';
    $testgroups_html .= "run on DB <b>$_</b></li>";
  }
  $testgroups_html   .= '</ul>';

  my $table           = EnsEMBL::Web::Document::HTML::TwoColTable->new;
  
  my $run_time        = defined $start_time && defined $end_time ? "<ul><li>Started: $start_time</li><li>Ended: $end_time</li></ul>" : " <i>(running time not known)</i>";

  $table->add_row("Last session:", $last_session_id.$run_time);
  $table->add_row("Host:", $last_session->host || '');
  $table->add_row("Testgroups:", $testgroups_html);

  return $table->render.$previous;
}

1;
