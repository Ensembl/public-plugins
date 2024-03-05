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

package EnsEMBL::Web::Ticket;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use URI::Escape qw(uri_escape);

use EnsEMBL::Web::Attributes;
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::File::Utils qw(get_compression);
use EnsEMBL::Web::File::Utils::URL;
use EnsEMBL::Web::File::Utils::IO;

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

sub get_input_file_content {
  ## Gets content from the uploaded/remote file or text entered in the form
  ## @param Method used - upload|url|text
  ## @param (optional) Name of the http param that contains file source (defaults to method)
  ## @return File content
  ## @return File name
  my ($self, $method, $param) = @_;

  my $hub     = $self->hub;
  my $file    = $hub->param($param || $method);
  my ($content, $name, $cmprs);

  if ($method eq 'url') {

    my $proxy = $hub->web_proxy;
       $proxy = $proxy ? { 'proxy' => $proxy } : {};
       $cmprs = get_compression($file);
    $content  = EnsEMBL::Web::File::Utils::URL::read_file($file, $proxy);
    $name     = $file =~ s/[^\?]+\/([^\/\?]+).*$/$1/r; # remove extra path from full file path

  } elsif ($method eq 'file') {

    $name     = "$file"; # $file->asString
    $cmprs    = get_compression($name);
    $content  = EnsEMBL::Web::File::Utils::IO::read_file($hub->input->tmpFileName($file), { 'compression' => $cmprs });

  } elsif ($method eq 'text') {
    $content  = $file;
    $name     = 'input.txt';
  }

  if ($cmprs) {
    $name =~ s/\.$cmprs$// if $cmprs;
    $name = "$name.txt" if $name !~ /\./;
  }

  # just allow limited set of characters in the file name
  $name =~ s/[^a-zA-Z0-9\-\_\.]+/_/g;

  return ($content, $name);
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
    'owner_id'    => $user ? $user->user_id : $hub->session->session_id,
    'owner_type'  => $user ? 'user' : 'session',
    'created_at'  => $now,
    'modified_at' => $now,
    'site_type'   => $sd->tools_sitetype,
    'ticket_name' => $ticket_name,
    'release'     => $sd->ENSEMBL_VERSION,
    'job'         => [ map { $_->rose_object } @$jobs ]
  });

  $ticket_type->save('changes_only' => 1);

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

  my ($heading, $message);

  if ($exception->type eq 'InputError') {
    $heading = 'Invalid input';
    $message = $exception->message(($exception->data || {})->{'message_is_html'})
  } else {

    my $error_types = {
      'input'       => 'Error occurred while reading job input',
      'toolsdb'     => 'Error occurred while saving job data',
      'dispatcher'  => 'Error occurred while submitting job'
    };
    $heading = $error_types->{$stage};

    my $error_id = substr(md5_hex($exception->message), 0, 10); # in most cases, will generate same code for same errors

    warn "ERROR: $error_id (stage: $stage)\n";
    warn $exception;
    
    my $sd = $self->hub->species_defs; 

    my $subject = sprintf('Tools error: %s - %s', $heading, $sd->ENSEMBL_SERVERNAME);
  
    my $body = sprintf("Ticket: %s\nReference: %s\nStage: %s\nReferrer: %s\nError: %s",
                $self->{'_rose_object'} ? $self->{'_rose_object'}->ticket_name : 'Not saved',
                $error_id,
                $stage,
                $self->hub->referer,
                substr($exception->message, 0, 50) =~ s/\R//gr);

    $message = sprintf('<p>There was a problem with one of the tools servers. Please report this issue to our <a href="mailto:%s?subject=%s&body=%s">HelpDesk</a> with the details below.</p><pre>%s</pre>',
                  $sd->ENSEMBL_HELPDESK_EMAIL,
                  uri_escape($subject),
                  uri_escape($body),
                  $body);
  }

  $self->{'_error'} = {
    'heading' => $heading,
    'stage'   => $stage,
    'message' => $message
  };
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
