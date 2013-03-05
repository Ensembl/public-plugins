package EnsEMBL::Web::Component::Tools::JobsList;

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
  my $object = $self->object;
  my $html ='<h2>Recent Jobs:</h2>';
  my $toggle = '0';
  my $hide;

  if ($self->hub->action eq 'BlastResults'){
    $hide = $self->hub->get_cookie_value('toggle_job_status') eq 'closed';
    $html = sprintf ('<h3><a rel ="job_status" class="toggle set_cookie %s" href="#">Recent Jobs:</a></h3>',
            $hide ? 'closed' : 'open'
            );

    $toggle = '1';
  } 

  $html .= '<input type="hidden" class="panel_type" value="Jobs" />';

  my $tickets = $object->fetch_current_tickets;
   
  my $table =  $self->new_table([], [], { toggleable => $toggle, class => ($hide ? ' hide' : ''), data_table => 'no_col_toggle', exportable => 0, sorting => [ 'created desc'], id => 'job_status'});
  $table->add_columns(
    { 'key' => 'analysis',  'title' => 'Analysis',    'align' => 'left',    sort => 'string' },
    { 'key' => 'ticket',    'title' => 'Ticket',      'align' => 'left',    sort => 'string' },
    { 'key' => 'desc',      'title' => 'Description', 'align' => 'left',    sort => 'string' }, 
    { 'key' => 'created',   'title' => 'Submitted',   'align' => 'left',    sort => 'string' },
    { 'key' => 'status',    'title' => 'Status',      'align' => 'left',    sort => 'string' },
    { 'key' => 'results',   'title' => '',            'align' => 'left',    sort => 'none'   },
    { 'key' => 'save',      'title' => '',            'align' => 'left',    sort => 'none'   },
    { 'key' => 'remove',    'title' => '',            'align' => 'left',    sort => 'none'   },
  );

  if ($tickets && scalar @$tickets > 0 ){

    my @rows;
    foreach my $ticket (@$tickets){  
      my $img_url = $self->img_url .'16/';
      my $created = $ticket->created_at;
      my $formatted_date = $object->format_date($created);
      my $desc = $ticket->ticket_desc || '-';
      my $analysis = $ticket->job->job_name;
      my $status = $ticket->status =~ /Completed|Failed/ ? $ticket->status : $object->check_submission_status($ticket);
      my $class = $status =~ /Completed|Failed/ ? 'complete' : 'incomplete';  
      my $results_image = $status =~ /Failed/ ? 'alert.png' : 'eye.png';
      my $results_text = $status =~ /Failed/ ? 'Display reason for failure' : 'View Results';
      my $results_url = $self->hub->url({ type => 'Tools', action => $analysis.'Results', tk => $ticket->ticket_name });
      my $display_link = $ticket->status =~ /Completed|Failed/ ? undef : 'class=hidelink';
      my $save_icon = $self->hub->user =~/\d+/ ? 'save.png' : 'dis/save.png';
      my $save_text = $self->hub->user =~/\d+/ ? 'Save job to user account' : 'Log in to save Job';

      my $results = sprintf ('<a %s href="%s"><img src="%s%s" alt="%s" title="%s"/></a>',
        $display_link,
        $results_url,
        $img_url,
        $results_image,
        $results_text,
        $results_text
      );

      my $save = sprintf ('<a %s><img src="%s%s" alt="%s" title="%s"/></a>',
       $display_link,
       $img_url, 
       $save_icon,
       $save_text,
       $save_text
      );

      my $delete = sprintf ('<a %s><img src="%strash.png" alt="%s" title="%s"/></a>', 
        $display_link,
        $img_url, 
        'Delete job', 
        'Delete job'
      );

      my $row = {
        analysis =>  $analysis,
        ticket    => { value => $ticket->ticket_name, class => 'ticket_id' },
        desc      => $desc,
        created   => $formatted_date,
        status    => { value => $status, class => 'status' },
        options   => { id => $ticket->ticket_name, class => $class  },
        results   => { class => 'results', value => $results },  
        remove    => { class => 'remove', value => $delete }, 
        save      => { class => 'save', value => $save },
      };
      push @rows, $row;
    }

    $table->add_rows(@rows);
  } 

  $html .= $table->render;

  $html .= '<div class="countdown"></div>';
  $html .= '<p class="no_jobs" style="space-below">You have no jobs currently running or recently completed.</p>';
  $html .= '</div>';
  return $html;
};

1;
