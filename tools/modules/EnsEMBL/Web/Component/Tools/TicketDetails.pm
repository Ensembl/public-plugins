package EnsEMBL::Web::Component::Tools::TicketDetails;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);
use Data::Dumper;

sub _init {  my $self = shift;
  $self->cacheable(0);  $self->ajaxable(1);
}

sub content {  
  my $self = shift;
  my $object = $self->object;
  my $hub = $self->hub;


  return $self->select_ticket('Blast') unless $hub->param('tk');

  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  unless ( ref($ticket) ){    return $self->select_ticket('Blast', $ticket);
  }

  my $ticket_name = $hub->param('tk');

  my $html = "<h2>Detailed status for ticket $ticket_name </h2>";
 
  my @hive_jobs = @{$ticket->sub_job};
 
  if ( scalar @hive_jobs > 1 ){
    my $split_prefix = $hive_jobs[0]->job_division;
    my $split = $split_prefix =~/^spp:/ ? 'species' : undef;
    $html .= sprintf ( '<p>This ticket was split by %s into %s jobs. The status of each individual job is in the table below.</p>',
      $split,
      scalar @hive_jobs
    );

    my $table = $self->new_table([], [], { data_table => 'no_col_toggle', exportable => 0, sorting => [ 'created desc'], id => 'job_status'});
     $table->add_columns(
      { 'key' => 'division',  'title' => 'Job split',   'align' => 'left',    sort => 'string' },
      { 'key' => 'status',    'title' => 'Status',      'align' => 'left',    sort => 'string' }
  );
 

    my @rows;
    my $error_flag =undef;;

    foreach my $job (@hive_jobs){
      my $division = $job->job_division;
      $division =~s/^\w*://;
      my $status = $object->get_hive_job_status($job->sub_job_id);
      my $error;
      if ($status eq 'Failed'){
        $error = $object->get_hive_job_message($job->sub_job_id);
        unless( $error_flag){ 
          $table->add_columns({ 'key' => 'error',     'title' => 'Reason for failure',            'align' => 'left',    sort => 'none'   });
        }  
        $error_flag =1;
    }

      my $row = {
        division    => $division,
        status      => $status,
        error       => $error,
      };

      push @rows, $row;
    }
  
    $table->add_rows(@rows);

    $html .= $table->render;    
  }

  return $html;
}

1;
