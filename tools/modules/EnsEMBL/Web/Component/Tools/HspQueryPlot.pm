package EnsEMBL::Web::Component::Tools::HspQueryPlot;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  my $object = $self->object; 
  my $html;

  return unless $hub->param('tk');

  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  return unless ref($ticket);

  my @hive_jobs = @{$ticket->sub_job};
  my (@results, @features);
  my $status = $ticket->status;
  
  return unless $status eq 'Completed';

  foreach my $hive_job (@hive_jobs ){
    if ($status eq 'Completed'){
      my $sub_job_id = $hive_job->sub_job_id;
      my $ticket_id = $ticket->ticket_id;

      @results = @{$object->rose_manager('Result')->fetch_results_by_ticket_sub_job($ticket_id, $sub_job_id)};
      return if scalar @results < 1;
    }
  }

  my $bucket = EnsEMBL::Web::Container::HSPContainer->new($object, $ticket, \@results);
  my $image_config = $hub->get_imageconfig('hsp_query_plot');

  my $hsp_dc = Bio::EnsEMBL::DrawableContainer->new($bucket, $image_config);
  my $image = EnsEMBL::Web::Document::Image->new($hub);
  $image->drawable_container = $hsp_dc; 
  $image->imagemap = 'yes';
  $image->set_button('drag');


  $html .= $image->render; 
  return $html;
}

1;
