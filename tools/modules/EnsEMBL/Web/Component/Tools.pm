package EnsEMBL::Web::Component::Tools;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component);

sub object {
  ## @override
  ## Gets the object according to the URL 'action' instead of the 'type' param, as expected in the tools based components
  return shift->SUPER::object->get_sub_object;
}

sub _init {
  ## Makes all the components in tools ajaxable but not cacheable
  ## Override this in a child class to modify the default behaviour
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub expand_job_status {
  ## Reads the job hive_status field, and display status accordingly
  ## @param Job object
  ## @param Extra params hashref with keys:
  ##  - links: Arrayref with name of the links that need to be displayed (results, edit, delete)
  ## @return DIV node
  my ($self, $job, $params) = @_;

  my $hub             = $self->hub;
  my $job_id          = $job->job_id;
  my $job_hive_status = ucfirst $job->hive_status =~ s/_/ /gr;
  my $job_message     = $job->job_message->[0];
  my $job_status      = $job->status;
  my $url_param       = $self->object->create_url_param({'ticket_name' => $job->ticket->ticket_name, 'job_id' => $job_id});
  my $job_status_div  = $self->dom->create_element('div', {
    'children' => [{
      'node_name'   => 'p',
      'inner_HTML'  => $job_hive_status
    }]
  });

  my $icons_bar;
  my $icons = { $job_status eq 'done' ? (
    'results' => {'icon' => 'view_icon',    'title' => 'View results',        'url' => {'function' => 'Results',  'tl' => $url_param}} ) : (),
    'edit'    => {'icon' => 'edit_icon',    'title' => 'Edit &amp; resubmit', 'url' => {'function' => 'Edit',     'tl' => $url_param}},
    'delete'  => {'icon' => 'delete_icon',  'title' => 'Delete',              'url' => {'function' => 'Delete',   'tl' => $url_param}}
  };
  foreach my $link (@{($params || {})->{'links'} || []}) {
    if ($icons->{$link}) {
      $icons_bar ||= $job_status_div->append_child('p', {'class' => 'job-links'});
      $icons_bar->append_child('a', {
        'href'      => $hub->url($icons->{$link}{'url'}),
        'children'  => [{
          'node_name' => 'span',
          'class'     => ['sprite', $icons->{$link}{'icon'}, '_ht'],
          'title'     => $icons->{$link}{'title'}
        }]
      });
    }
  }

  if ($job_status eq 'awaiting_user_response') {

    my $display_message         = $job_message->display_message;
    my $exception_is_fatal      = $job_message->fatal;
    my $job_message_class       = "_job_message_$job_id";

    $job_status_div->first_child->inner_HTML(sprintf '%s: %s%s',
      $job_hive_status,
      $display_message,
      $job_message->fatal ? sprintf(' <a class="toggle closed" href="#more" rel="%s">more</a>', $job_message_class) : ''
    );

    if ($exception_is_fatal) {
      my $exception = $job_message->exception;
      my $details   = $exception->{'message'} ? "Uncaught exception with message: $exception->{'message'}\n" : "Uncaught exception:\n";
         $details  .= $exception->{'stack'}
        ? join("\n", map(sprintf("Thrown by %s at %s (%s)", $_->[3], $_->[0], $_->[2]), @{$exception->{'stack'}}))
        : $exception->{'exception'} || 'Not details'
      ;

      my $helpdesk_details = sprintf 'This seems to be a problem with %s website code. Please contact our <a href="%s" class="modal_link">helpdesk</a> to report this problem.',
        $hub->species_defs->ENSEMBL_SITETYPE,
        $hub->url({'type' => 'Help', 'action' => 'Contact', 'subject' => 'Exception in Web Tools', 'message' => sprintf("\n\n\n%s with message (%s) (for job %s): %s", $job_message->exception->{'class'} || 'Exception', $display_message, $job_id, $details)})
      ;

      $job_status_div->insert_after({
        'node_name'   => 'div',
        'children'    => [{
          'node_name'   => 'div',
          'class'       => [ $job_message_class, 'toggleable', 'hidden', 'job_error_message' ],
          'inner_HTML'  => $details
        }, {
          'node_name'   => 'p',
          'inner_HTML'  => $helpdesk_details
        }],
      }, $job_status_div->first_child);
    }

  }

  return $job_status_div;
}


#####
 ## TODO 
sub select_ticket {
  my ($self, $type, $error) = @_;
  
  my $html = '<h2>Select a ticket to see results:</h2>';
  if ($error){ $html .= "<p class='error space-below'>$error </p>";}
  $html .= 'Please select a ticket from recent jobs table or enter a ticket name into the search box below to display results for that ticket:';

  my $action = $type . 'Results';
  my $url = $self->hub->url({ type => 'Tools', action => $action} );
  $html .= qq{
    <div>
    <form action="$url" method="get">
    <input id="ticket" name="tk" />
    <input type="submit" value="Go" class="input-submit" />
    </form>
    </div>
  }; 

  return $html;
}

sub get_download_link {
  my ($self, $ticket, $format, $filename) = @_;
  my $hub = $self->hub;

  my $url = $hub->url({
    'type'    => 'Tools',
    'format'  => $format,
    'action'  => 'Download',
    'tk'      => $ticket,
    'file'    => $filename,
    '_format' => 'Text'
  });

  return $url;  
}

sub failure_message {
  my ($self, $ticket) = @_;
  my $analysis = $ticket->job_type->caption;  
  my $error = $self->object->error_message($ticket); 

  return $self->_error(
    $analysis . ' Failed',
    '<p>Unknown error</p>'
  );
}

sub pointer_default {
  my ($self, $feature_type) = @_;

  my %hash = (
    Blast           => [ 'rharrow', 'gradient', [qw(90 gold orange chocolate firebrick darkred)]],
  );

  return $hash{$feature_type};
}

1;
