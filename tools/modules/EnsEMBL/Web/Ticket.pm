=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Ticket;

use strict;
use warnings;

use EnsEMBL::Web::Attributes;
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Utils::RandomString qw(random_string);

sub hub         { return shift->{'_hub'};         }
sub object      { return shift->{'_object'};      }
sub rose_object { return shift->{'_rose_object'}; }
sub jobs        { return shift->{'_jobs'};        }
sub error       { return shift->{'_error'};       }

sub process {
  my $self  = shift;
  my $stage = '';

  try {

    # get input from form
    $stage = 'input';
    $self->init_from_user_input;

    # submit ticket and jobs to the tools db
    $stage = 'toolsdb';
    $self->submit_to_toolsdb;

    # dispatch the job(s) to job dispatcher
    $stage = 'dispatcher';
    $self->dispatch_jobs;

  } catch {

    # ok, now deal with it
    $self->handle_exception($_, $stage);
  };
}

sub new {
  ## @constructor
  my ($class, $object) = @_;
  return bless {
    '_object'       => $object,
    '_hub'          => $object->hub,
    '_jobs'         => [],
    '_rose_object'  => undef,
    '_error'        => ''
  }, $class;
}

sub init_from_user_input :Abstract {
  ## @abstract method
  ## This method should read the raw form parameters, validate them and convert them into an array of EnsEMBL::Web::Job or sub class
}

sub submit_to_toolsdb {
  ## Creates entries in the tools db in the ticket table and the job table
  ## Also creates a job folder for writing i/o files (in the tools tmp directory) and saves input files to it
  my $self        = shift;
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $object      = $self->object;
  my $user        = $hub->user;
  my $now         = $object->get_time_now;
  my $tool_type   = $object->tool_type or throw exception('WebError', 'Ticket can not be submitted without specifying a ticket type');
  my $ticket_type = $object->rose_manager(qw(Tools TicketType))->get_objects('query' => [ 'ticket_type_name' => $tool_type ])->[0];
  my $ticket_name = $object->generate_ticket_name;
  my $jobs        = $self->jobs;

  my %job_nums;

  for (@$jobs) {

    my $job_num = $_->get_param('job_number') || 1;

    $_->set_params({
      'job_number'  => $job_num,
      'modified_at' => $now,
      'job_dir'     => $self->is_dir_needed ? $_->create_work_dir({
        'job_number'  => $job_num,
        'ticket_type' => $ticket_type->ticket_type_name,
        'ticket_name' => $ticket_name,
        'persistent'  => $user ? 1 : 0,
      }) : undef
    });

    throw exception('WebError', 'Multiple jobs can not be submitted with same job number') if $job_nums{$job_num}; # can't have more than one jobs with same job number

    $job_nums{$job_num} = 1;
  }

  my ($tools_ticket) = $ticket_type->add_ticket({
    'owner_id'    => $user ? $user->user_id : $hub->session->create_session_id,
    'owner_type'  => $user ? 'user' : 'session',
    'created_at'  => $now,
    'modified_at' => $now,
    'site_type'   => $sd->ENSEMBL_SITETYPE,
    'ticket_name' => $ticket_name,
    'release'     => $sd->ENSEMBL_VERSION,
    'job'         => [ map { $_->rose_object } @$jobs ]
  });

  # try to save ticket to the tools db, but if it fails, try for another three times before giving up (useful in case deadlocks)
  foreach my $tries_left (reverse 0..3) {

    try {
      $ticket_type->save('changes_only' => 1);
      $tries_left = -1;
    } catch {
      throw $_ unless $tries_left;
      sleep 1;
    };

    last if $tries_left < 0;
  }

  $self->{'_rose_object'} = $tools_ticket;
}

sub dispatch_jobs {
  ## Submits the jobs via the required job dispatcher
  my $self          = shift;
  my $object        = $self->object;
  my $hub           = $self->hub;
  my $tools_ticket  = $self->rose_object;
  my $ticket_id     = $tools_ticket->ticket_id;
  my $ticket_name   = $tools_ticket->ticket_name;
  my $ticket_type   = $tools_ticket->ticket_type_name;

  foreach my $job (@{$self->jobs}) {

    if (my $dispatcher_data = $job->prepare_to_dispatch) {

      # add some generic info to job data to be submitted
      $dispatcher_data->{'ticket_id'}   = $ticket_id;
      $dispatcher_data->{'ticket_name'} = $ticket_name;
      $dispatcher_data->{'job_id'}      = $job->get_param('job_id');
      $dispatcher_data->{'species'}     = $job->get_param('species');

      # Dispatch the job
      my $dispatcher            = $job->get_dispatcher_class($dispatcher_data);
         $dispatcher            = $object->get_job_dispatcher($dispatcher ? {'class' => $dispatcher} : {'ticket_type' => $ticket_type});
      my $dispatcher_reference  = $dispatcher->dispatch_job($ticket_type, $dispatcher_data);

      # Save the extra info in the tools db
      if ($dispatcher_reference) {
        $job->set_params({
          'dispatcher_class'      => [ split /::/, ref $dispatcher ]->[-1],
          'dispatcher_reference'  => $dispatcher_reference,
          'dispatcher_data'       => $dispatcher_data,
          'dispatcher_status'     => 'queued',
          'status'                => 'awaiting_dispatcher_response'
        });
      }
    }

    $job->save('changes_only' => 1); # only update if anything changed (prepare_to_dispatch method may also have changed the job, so keep this outside the if statement)
  }
}

sub handle_exception {
  ## Handles exceptions when thrown by the process method
  ## Override it in the sub class or plugin to change its behaviour
  ## @param EnsEMBL::Web::Exception object
  ## @param Stage at which exception was thrown (String)
  my ($self, $exception, $stage) = @_;

  if ($exception->type eq 'InputError') {
    $self->{'_error'} = {
      'heading' => 'Invalid input',
      'stage'   => $stage,
      'message' => $exception->message(($exception->data || {})->{'message_is_html'})
    };
  } else {
    my $error_id = random_string(8);
    warn "ERROR: $error_id (stage: $stage)\n";
    warn $exception;

    $self->{'_error'} = {
      'heading' => 'Service unavailable',
      'stage'   => $stage,
      'message' => sprintf(q(There was a problem with one of the tools servers. Please report this issue to %s, quoting error reference '%s'.), $self->hub->species_defs->ENSEMBL_HELPDESK_EMAIL, $error_id)
    };
  }
}

sub add_job {
  ## Adds a job object to the jobs array
  ## @param EnsEMBL::Web::Job object
  my ($self, $job) = @_;
  push @{$self->{'_jobs'}}, $job;
}

sub is_dir_needed {
  ## Flag to tell whether a work dir in the shared location is needed to save the input files (or run the jobs)
  ## Override if required
  return 1;
}

1;
