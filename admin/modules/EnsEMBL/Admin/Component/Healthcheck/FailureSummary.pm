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
  my $reports   = $object->rose_objects('reports');
  my $reports2  = $object->rose_objects('compare_reports');
  my $release   = $object->requested_release;
  my $views     = $object->available_views;

  return unless $session && @$reports;

  $reports      = $self->group_report_counts($reports,  [values %$views]);
  $reports2     = $self->group_report_counts($reports2, [values %$views]) if $reports2;

  my $form      = $self->get_all_releases_dropdown_form('Compare with', 'release2');
  $form->add_hidden({'name' => 'release', 'value' => $release});

  my $html      = $form->render.qq(<div class="_hc_infobox tinted-box"><p>Tests listed as failed are of type 'PROBLEM', excluding those annotated 'manual ok', 'manual ok this assembly', 'manual ok all releases', 'healthcheck bug'</p></div>);
  my $buttons   = $self->dom->create_element('div', {'class' => 'ts-buttons-wrap hc-tabs'});
  my $tabs      = $self->dom->create_element('div', {'class' => 'spinner ts-spinner _ts_loading'});

  foreach my $view_function (sort keys %$views) {

    my $view_type = $views->{$view_function};
    my $params    = {
      'count'         => $reports->{$view_type},
      'type'          => $view_type,
      'session_id'    => $session->session_id,
      'release'       => $release,
      'default_list'  => $object->get_default_list($view_type, $view_function),
      $reports2 ? (
      'compare_count' => $reports2->{$view_type},
      'release2'      => $object->compared_release
      ) : ()
    };
    $buttons->append_child('a', {'class' => '_ts_button ts-button', 'href' => "#$view_type", 'inner_HTML' => $object->view_title($view_type)});
    $tabs->append_child('div', {'class' => '_ts_tab ts-tab', 'inner_HTML' => $self->failure_summary_table($params)});
  }
  return sprintf($html . $self->dom->create_element('div', {'class' => '_tabselector', 'children' => [$buttons, $tabs]})->render);
}

1;