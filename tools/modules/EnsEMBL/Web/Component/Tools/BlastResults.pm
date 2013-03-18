package EnsEMBL::Web::Component::Tools::BlastResults;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);
use EnsEMBL::Web::Form;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self   = shift;
  my $hub    = $self->hub;
  my $object = $self->object;

  return $self->select_ticket('Blast') unless $hub->param('tk');
  
  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  unless ( ref($ticket) ){ 
    my $error = $self->_error('Ticket not found', $ticket, '100%');
    return $self->select_ticket('Blast', $error);
  }

  ## We have a ticket!
  my $html;
  my $name = $ticket->ticket_name;

  my $status = $ticket->status;
  
  my @hive_jobs = @{$ticket->sub_job};

  return $self->failure_text($ticket) if $status eq 'Failed';

  unless ($ticket->result ) {
    my $text = "<p>If you believe that there should be a match to your query sequence(s) please adjust the configuration parameters you selected and resubmit the search.</p>";
    $html .= $self->_error('No results found', $text, '100%' );
    return $html;  
  }

  $html .= '<p class="space-below">';
  if (scalar @hive_jobs > 1){
    $html .= sprintf 'This task was split into %s sub tasks, based on species', scalar @hive_jobs;
  }
 
  foreach my $hive_job (@hive_jobs ){
    if ($status eq 'Completed'){
      my $sub_job_id = $hive_job->sub_job_id;
      my $ticket_id = $ticket->ticket_id;
      my $filename =  $ticket->ticket_id . $sub_job_id . '.seq.fa.raw';
      my $raw_output_link = $self->get_download_link($name, 'raw', $filename); 
      my $job_division = $object->deserialise($hive_job->job_division);  
      my $job_summary = $self->summary($ticket, $hive_job);     

      $html .= $job_summary;  
      $html .= sprintf '<a href="%s" rel="external">View raw results file. <img src="/i/16/download.png" alt="download" title="Download" /></a>', $raw_output_link;
    }
  }

  $html .= '</p>';
  return $html;
}

sub summary {
  my ($self, $ticket, $sub_job) = @_;

  my $object = $self->object;
  my $blast_object = $object->deserialise($ticket->analysis->object);
  my $job_desc = $blast_object->{'_description'} ."   ";
  return $job_desc;
}

sub failure_text {
  my ($self, $ticket) = @_;
  my $html;

  my $text = "<p>This search failed to run sucessfully. The error reported was: </p>";
  $html .= $self->_error('BLAST/BLAT Search Failed', $text, '100%' );

  return $html;  
}

1;
