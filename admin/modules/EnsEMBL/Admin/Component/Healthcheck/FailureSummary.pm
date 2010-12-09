package EnsEMBL::Admin::Component::Healthcheck::FailureSummary;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  return 'Summary of failed healthchecks';
}

sub content {
  my $self = shift;
  
  my $hub                     = $self->hub;
  my $db_interface            = $self->object;
  my $release                 = $hub->param('release') || $hub->species_defs->ENSEMBL_VERSION;

  return '' unless $self->validate_release($release);
  
  my $session_db_interface  = $db_interface->data_interface('Session');
  my $last_session          = $session_db_interface->fetch_last($release);
  my $last_session_id       = $last_session ? $last_session->session_id || 0 : 0;
  
  return '' unless $last_session_id;
  
  my $first_session         = $session_db_interface->fetch_first($release);
  my $first_session_id      = $first_session ? $first_session->session_id || 0 : 0;
 
  my $report_db_interface = $db_interface->data_interface('Report');
  my $all_reports         = $report_db_interface->fetch_all_failed_for_session($last_session_id);
  
  my $select_box          = $self->render_all_releases_selectbox($release);
  $select_box             =~ s/"release"/"release2"/;

  my $html_anchor         = '';
  my $html                = qq(<form action="" method="get"><p class="hc_p_right"><input type="hidden" name="release" value="$release" />Compare with: $select_box&nbsp;<input type="submit" value="Go" /></p></form>);

  $html                  .= qq(<div class="hc-infobox">
                              <p>Tests listed as failed are of type 'PROBLEM', excluding those annotated 'manual ok', 'manual ok this assembly', 'manual ok all releases', 'healthcheck bug'</p>
                              </div>);

  
  my $release_2           = $hub->param('release2') || 0;
  my %comparison_params   = ('release_2' => $hub->param('release2') || 0);

  #if comparison intended
  if ($self->validate_release($comparison_params{'release_2'})) {
    my $last_session_2                    = $session_db_interface->fetch_last($release_2);
    my $last_session_id_2                 = $last_session_2 ? $last_session_2->session_id || 0 : 0;
    $comparison_params{'compare_reports'} = $report_db_interface->fetch_all_failed_for_session($last_session_id_2) if $last_session_id_2;
  }
  
  foreach my $view (qw(database_type species testcase database_name)) {

    (my $perspective = ucfirst($view)) =~ s/_/ /g;
    $html                .= qq(<a name="$view"></a><p class="hc_p">Failure summary for: <b>$perspective</b></p>);
    $html_anchor         .= qq(&nbsp;<a href="#$view">$perspective</a>&nbsp;);
    
    $html                .= $self->content_failure_summary({
      'view'                => $view,
      'last_session_id'     => $last_session_id,
      'first_session_id'    => $first_session_id,
      'release'             => $release,
      'all_reports'         => $all_reports,
      'report_db_interface' => $report_db_interface,
      %comparison_params
    });
  }
  $html_anchor = qq(<p class="hc_p">Go to perspective: ).$html_anchor.qq(</p>);
  return $html_anchor.$html;
}

1;