package EnsEMBL::Admin::Command::Healthcheck::Annotation;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  
  my $report_db_interface = $self->object->data_interface('Report');
  my $hub = $self->hub;

  my $report_id = $hub->param('rid'); 
  $report_id    = [ split ',', $report_id ], #in case multiple reports
  my $reports   = $report_db_interface->fetch_by_id($report_id, 1); #fetch_report_id(ArrayRef $report_id, Boolean $failed_only)

  unless (scalar $reports) {
    warn 'No report found to annotate. (Invalid report id)';
    return;
  }
  
  my $current_user_id = $hub->user->user_id;
  my ($sec, $min, $hour, $day, $mon, $year) = localtime();
  my $now = (1900+$year).'-'.sprintf('%02d', $mon+1).'-'.sprintf('%02d', $day).' '
              .sprintf('%02d', $hour).':'.sprintf('%02d', $min).':'.sprintf('%02d', $sec);

  for (@$reports) {
    
    my $annotation = undef;
    if ($_->annotation) {
      #edit existing annotation
      $annotation = $_->annotation;
      $annotation->modified_by($current_user_id);
      $annotation->modified_at($now);
    }
    else {
      #add new if no annotation found linked to the report
      $annotation = $report_db_interface->create_empty_object('EnsEMBL::Admin::Rose::Object::Annotation'); 
      $annotation->created_by($current_user_id);
      $annotation->created_at($now);
      $annotation->report_id($_->report_id); #don't forget to link it to the report
    }

    $annotation->comment($hub->param('comment'));
    $annotation->action($hub->param('action'));
    $annotation->save;

  }
  
  my $urn   = '/Healthcheck/Summary'; 
  my $vars  = {};
  if ($hub->param('referrer')) {
    $urn      = [split (/\?/, $hub->param('referrer'))];
    my $uri   = $urn->[1] ? [split /\&|\;/, $urn->[1]] : [];
    for (@$uri) {
      $vars->{ $1 } = $2 if $_ =~ /([^\=]+)\=([^\;\&]+)/;
    }
  }
  $self->ajax_redirect($urn->[0], $vars, $reports->[0]->database_name || '');
}

1;