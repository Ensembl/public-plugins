=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Component::Tools::TicketDetails;

### Parent class for tools TicketDetails
### Shall be used with MI

use strict;
use warnings;

sub view_type {
  ## Gets the view type for the component (View and Result display things differently)
  my $self      = shift;
  my $hub       = $self->hub;
  my $function  = $hub->function || '';

  return 'Results'  if $function eq 'Results';
  return 'View'     if $function eq 'View' || $hub->param('view');
  return '';
}

sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @param Flag to tell whether user or session owns the ticket or not
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job, $is_owned_ticket) = @_;

  my $object    = $self->object;
  my $job_data  = $job->job_data;
  my $species   = $job->species;
  my $sd        = $self->hub->species_defs;
  my $two_col   = $self->new_twocol;

  $two_col->add_row('Job summary',  $self->get_job_summary($job, $is_owned_ticket)->render);
  $two_col->add_row('Species',      $object->valid_species($species)
    ? sprintf('<img class="job-species" src="%sspecies/%s.png" alt="" height="16" width="16">%s', $self->img_url, $species, $sd->species_label($species, 1))
    : $species =~ s/_/ /rg
  );
  $two_col->add_row('Assembly',     $job->assembly);

  return $two_col;
}

sub get_job_summary {
  ## Reads the job dispatcher_status field, and display status accordingly
  ## @param Job object
  ## @param Flag to tell whether user or session owns the ticket or not
  ## @return DIV node
  my ($self, $job, $is_owned_ticket) = @_;

  my $hub               = $self->hub;
  my $object            = $self->object;
  my $job_id            = $job->job_id;
  my ($job_message)     = sort { $a->fatal ? -1 : 1 } @{$job->job_message}; # give priority to a fatal exception
  my $job_status        = $job->status;
  my $dispatcher_status = $job->dispatcher_status;
  my $url_param         = $object->create_url_param({'job_id' => $job_id});
  my $job_status_div    = $self->dom->create_element('div', {
    'children'            => [{
      'node_name'           => 'p',
      'inner_HTML'          => $object->get_job_description($job)
    }, {
      'node_name'           => 'p',
      'class'               => 'job-icons'
    }]
  });

  my $icons = {
    'edit'    => {
      'icon'    => 'edit_icon',
      'title'   => 'Edit &amp; resubmit (create new ticket)',
      'url'     => [{ 'function' => 'Edit', 'tl' => $url_param }],
      'class'   => '_ticket_edit _change_location'
    },
    'delete'  => {
      'icon'        => 'delete_icon',
      'title'       => 'Delete',
      'url'         => ['Json', {'function' => 'delete',  'tl' => $url_param  }],
      'redirectUrl' => $hub->url({ 'function' => '', 'tl' => undef}),
      'class'       => '_ticket_delete _json_link',
      'confirm'     => 'This will delete this job permanently.'
    }
  };

  my $margin_left_class = @{$job_status_div->last_child->child_nodes} ? 'left-margin' : ''; # set left margin only if required
  foreach my $link ($is_owned_ticket ? qw(edit delete) : qw(edit)) {
    if ($icons->{$link}) {
      $job_status_div->last_child->append_child('a', {
        'href'              => $hub->url(@{$icons->{$link}{'url'}}),
        'class'             => $icons->{$link}{'class'},
        'data-redirect-url' => $icons->{$link}{'redirectUrl'},
        'children'          => [{
          'node_name'       => 'span',
          'class'           => ['sprite', $icons->{$link}{'icon'}, '_ht', $margin_left_class || ()],
          'title'           => $icons->{$link}{'title'}
        }, $icons->{$link}{'confirm'} ? {
          'node_name'       => 'span',
          'class'           => ['hidden', '_confirm'],
          'inner_HTML'      => $icons->{$link}{'confirm'}
        } : () ]
      });
      $margin_left_class = '';
    }
  }

  if ($job_status eq 'awaiting_user_response') {

    my $display_message         = $job_message && $job_message->display_message || 'Unknown error';
    my $exception_is_fatal      = $job_message ? $job_message->fatal : 1;
    my $job_message_class       = "_job_message_$job_id";
    my $check_details_link      = sprintf('<a class="toggle _slide_toggle closed" href="#more" rel="%s">check the details</a>', $job_message_class);

   

    if ($exception_is_fatal) {
      my $exception = $job_message ? $job_message->exception : {};
      my $doc_link = '<a href="/info/docs/tools/vep/vep_formats.html">Click here for information on VEP file formats</a>';
      if ($exception && $exception->{'exception'}=~/ERROR: Can't detect format/) {

        $job_status_div->append_child('div', {
          'class'       => 'job-error-msg',
          'children'    => [{
            'node_name'   => 'p',
            'inner_HTML'  => '<b>Input Format Error:</b> Your input file is either incorrectly formatted or the format is unsupported. ' . $doc_link
          }]
        });
      }
      elsif ($exception && $exception->{'exception'}=~/ERROR: Unknown or unsupported format pileup/) {

        $job_status_div->append_child('div', {
          'class'       => 'job-error-msg',
          'children'    => [{
            'node_name'   => 'p',
            'inner_HTML'  => '<b>Input Format Error:</b> Pileup file format is no longer supported. ' . $doc_link
          }]
        });
      }
      else {
        my $details   = $exception->{'message'} ? "Error with message: $exception->{'message'}\n" : "Error:\n";
           $details   = $exception->{'stack'} ? $details : $details.$exception->{'exception'} || 'No details';
        
        my $helpdesk_link = $hub->url({'type' => 'Help', 'action' => 'Contact', 'subject' => sprintf('Exception in %s Web Tools', $hub->species_defs->ENSEMBL_SITETYPE), 'message' => sprintf("\n\n\n%s with message (%s) (for %s): %s", $exception->{'class'} || 'Exception', $display_message, $url_param, $details)});

         my $error_details_div = $self->dom->create_element('div', {
          'class'       => [ $job_message_class, 'toggleable', 'hidden', 'job_error_message' ],
          'inner_HTML'  => $details
        });
        
        if ($exception && $exception->{'message'}=~/\[Net::FTP\] Timeout/) {

          my $helpdesk_details = sprintf 'This tool is currently unavailable (%s). Please try again and if the error persists, contact our <a href="%s" class="modal_link">helpdesk</a> to report this problem.', $check_details_link, $helpdesk_link;

          $job_status_div->append_child('div', {
            'class' => 'job-error-msg',
            'children'    => [{ 
              'node_name'   => 'p',
              'inner_HTML'  => $helpdesk_details
            }, $error_details_div]
          });

        } else{

           my $error_div = $job_status_div->append_child('div', {
            'class'       => 'job-error-msg',
            'children'    => [{
              'node_name'   => 'p',
              'inner_HTML'  => join('', $display_message, $exception_is_fatal ? sprintf(' Please %s in case it is an error with the input data', $check_details_link) : '')
            }]
          });
          
          my $helpdesk_details = sprintf 'If the error persists, please contact our <a href="%s" class="modal_link">helpdesk</a> to report this problem.', $helpdesk_link;
          $error_div->append_children($error_details_div, {
            'node_name'   => 'p',
            'inner_HTML'  => $helpdesk_details
          });

        }
        
      }
    }
  }

  return $job_status_div;
}

sub content_ticket {
  ## @note Avoid overriding this in sub class
  ## @param Ticket object
  ## @param Arrayref if Job objects
  ## @param Flag to tell whether user or session owns the ticket or not
  ## @return HTML to be displayed
  my ($self, $ticket, $jobs, $is_owned_ticket) = @_;
  my $hub     = $self->hub;
  my $is_view = $self->view_type eq 'View';
  my $table;

  for (@$jobs) {
    $table = $self->job_details_table($_, $is_owned_ticket);
    $table->set_attribute('class', $is_view ? 'plain-box' : 'toggleable hidden _ticket_details');
  }

  return $table ? $table->render : '';
}

sub content {
  ## Actual method returning the content of the componet
  ## @note Avoid overriding this in sub class
  my $self      = shift;
  my $object    = $self->object;
  my $hub       = $self->hub;
  my $function  = $hub->function || '';
  my $ticket    = $self->view_type ? $object->get_requested_ticket : undef;
  my $jobs      = $ticket ? [ $object->parse_url_param->{'job_id'} ? $object->get_requested_job || () : $ticket->job ] : [];
  my $is_view   = $self->view_type eq 'View';

  my $heading = @$jobs ? $is_view
    ? sprintf('<h3>Job%s for %s ticket %s<a href="%s" class="left-margin _ticket_hide small _change_location">[Close]</a></h3>',
        @$jobs > 1 ? 's' : '',
        $ticket->ticket_type->ticket_type_caption,
        $ticket->ticket_name,
        $is_view ? $hub->url({'tl' => undef, 'function' => ''}) : '',
      )
    : '<h3><a rel="_ticket_details" class="toggle _slide_toggle closed" href="#">Job details</a></h3>'
    : ''
  ;

  return sprintf '<input type="hidden" class="panel_type" value="TicketDetails" />%s%s', @$jobs ? ($heading, $self->content_ticket($ticket, $jobs, scalar $object->user_accessible_tickets($ticket))) : ('', '');
}

1;
