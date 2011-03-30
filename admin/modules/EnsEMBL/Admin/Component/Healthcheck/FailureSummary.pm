package EnsEMBL::Admin::Component::Healthcheck::FailureSummary;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

sub caption {
  return 'Summary of failed healthchecks';
}

sub content {
  my $self = shift;

  my $object    = $self->object;
  my $session   = $object->rose_object;
  my $session_2 = $object->rose_objects('compare_session');
  my $release   = $object->requested_release;
  my $views     = $object->available_views;
  my $reports;
  my $reports_2;
  
  return unless $session && ($reports = $session->report);

  $reports_2 = $session_2 && @$session_2 ? $session_2->[0]->report : undef;

  (my $select_box = $self->render_all_releases_selectbox) =~ s/"release"/"release2"/;
  my $html_anchor = '';
  my $html        = qq(<form action="" method="get"><p class="hc_p_right"><input type="hidden" name="release" value="$release" />Compare with: $select_box&nbsp;<input type="submit" value="Go" /></p></form>);
  $html          .= qq(<div class="hc-infobox"><p>Tests listed as failed are of type 'PROBLEM', excluding those annotated 'manual ok', 'manual ok this assembly', 'manual ok all releases', 'healthcheck bug'</p></div>);

  foreach my $view_function (sort keys %$views) {

    my $view_type = $views->{$view_function};
    my $title     = $object->view_title($view_type);
    $html_anchor .= qq(&nbsp;<a href="#$view_type">$title</a>&nbsp;);
    $html        .= qq(<a name="$view_type"></a><p class="hc_p">Failure summary for: <b>$title</b></p>);
    my $params    = {
      'reports'       => $reports,
      'type'          => $view_type,
      'session_id'    => $session->session_id,
      'release'       => $release,
      'default_list'  => $object->get_default_list($view_type, $view_function)
    };
    $params->{'compare_reports'} = $reports_2 and $params->{'release2'} = $object->compared_release if $reports_2;
    $html .= $self->content_failure_summary($params);
  }
  $html_anchor = qq(<p class="hc_p">Go to perspective: ).$html_anchor.qq(</p>);
  return $html_anchor.$html;
}

1;