package EnsEMBL::Web::Object::Tools;

### Base abstract class for all the Tools based objects
### Avoid using an instance of this class, use child classes instances by calling get_sub_object() method

use strict;
use warnings;

use JSON qw(from_json);
use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

use EnsEMBL::Web::SpeciesDefs;
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Tools::RandomString qw(random_string);

use Bio::Root::IO;

use base qw(EnsEMBL::Web::Object);

sub caption               { return 'Tools'; } # override in child obects
sub short_caption         { return 'Tools'; } # override in child obects
sub long_caption          { return 'Tools'; } # override in child obects
sub default_error_message { return 'Some error occurred while running the job.'; }

sub get_sub_object {
  ## Gets the actual web object according to the 'action' part of the url
  ## @return Blast/VEP web object if available for the hub->action, Tools object otherwise
  my $self = shift;
  return $self->{'_sub_object'} ||= ref $self eq __PACKAGE__ && $self->new_object($self->hub->action, {}, $self->__data) || $self;
}

sub form_inputs_to_jobs_data {
  ## @abstract method
  ## @return Arrayref of jobs hashref, or undef of validation fails
  ## This method should read the raw form parameters, validate them and convert them into an array of hashes of jobs, each to be saved in the job_data column of ticket table in tools db
  ## undef is returned if validation failes as validation is already done on the frontend, if it still fails, someone's just messing around
  throw exception('AbstractMethodNotImplemented');
}

sub ticket_prefix {
  ## @abstract method
  ## Should return the ticket name prefix for the tool type, eg 'BLA_' for blast etc.
  throw exception('AbstractMethodNotImplemented');
}

sub ticket_type {
  ## @abstract method
  ## Should return the ticket type as saved in ticket_type table
  throw exception('AbstractMethodNotImplemented');
}

sub create_url_param {
  ## Creates a URL param from the given ticket or job
  ## The purpose of keeping these three params in one URL param is to prevent losing this info when clicking around the tabs on ensembl page
  ## @param Hashref with keys ticket_name, job_id and result_id
  ## If no key is provided, it returns current valid 'tl' param
  ## If only 'result_id' is provided, it uses ticket_name and job_id from current URL
  ## If only 'job_id' is provided, it uses ticket_name from the current URL
  my ($self, $params) = @_;

  if (!$params->{'ticket_name'}) {
    my $ex_params = $self->parse_url_param;
    if (!$params->{'job_id'}) {
      if (!$params->{'result_id'}) {
        $params->{'result_id'} = $ex_params->{'result_id'};
      }
      $params->{'job_id'} = $ex_params->{'job_id'};
    }
    $params->{'ticket_name'} = $ex_params->{'ticket_name'};
  }

  throw exception('ParamRequired', 'Ticket name is needed to create URL param') unless $params->{'ticket_name'};
  return join '-', grep $_, $params->{'ticket_name'}, $params->{'job_id'}, $params->{'result_id'};
}

sub parse_url_param {
  ## Reverse of create_url_param
  ## @return Hashref with keys: ticket_name OR job_id OR job_id and result_id
  my $self = shift;

  unless (exists $self->{'_url_param'}) {

    my @param = split '-', $self->hub->param('tl') || '';

    $self->{'_url_param'} = {
      'ticket_name' => $param[0],
      'job_id'      => $param[1],
      'result_id'   => $param[2]
    };
  }

  return $self->{'_url_param'};
}

sub process_job_for_hive_submission {
  ## @abstract method
  ## Should generate hive friendy parameters for a job depending upon the related ticket object
  ## @param Rose job object
  ## @return Hashref with required job params, or undef if job should not be submitted to hive
  throw exception('AbstractMethodNotImplemented');
}

sub hive_adaptor {
  ## Gets new or cached hive adaptor
  ## @return Bio::EnsEMBL::Hive::DBSQL::DBAdaptor object
  my $self = shift;

  unless ($self->{'_hive_adaptor'}) {
    my $sd      = $self->hub->species_defs;
    my $hivedb  = $sd->multidb->{'DATABASE_WEB_HIVE'};

    $self->{'_hive_adaptor'} = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new(
      -user   => $sd->DATABASE_WRITE_USER,
      -pass   => $sd->DATABASE_WRITE_PASS,
      -host   => $hivedb->{'HOST'},
      -port   => $hivedb->{'PORT'},
      -dbname => $hivedb->{'NAME'},
    );
  }
  return $self->{'_hive_adaptor'};
}

sub generate_ticket_name {
  ## Generates a unique ticket name
  ## @return String of length same as the column's allowed length for ticket name
  my $self    = shift;
  my $prefix  = $self->ticket_prefix;
  my $manager = $self->rose_manager(qw(Tools Ticket));
  my $length  = $manager->object_class->meta->column('ticket_name')->length - length $prefix;
  my $name    = '';

  while (!$name || !$manager->is_ticket_name_unique($name)) {
    $name = $prefix . random_string($length);
  }

  return $name;
}

sub create_ticket {
  ## creates a ticket for the jobs given by the user in the tools database and calls a method to submit them to hive database
  ## @param Arrayref of jobs data (as returned by form_inputs_to_jobs_data)
  my ($self, $jobs) = @_;

  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $now         = $self->get_time_now;
  my $ticket_type = $self->rose_manager(qw(Tools TicketType))->get_objects('query' => [ 'ticket_type_name' => $self->ticket_type ])->[0];

  my ($ticket)  = $ticket_type->add_ticket({
    'owner_id'    => $user ? $user->user_id : $hub->session->session_id,
    'owner_type'  => $user ? 'user' : 'session',
    'created_at'  => $now,
    'modified_at' => $now,
    'site_type'   => $hub->species_defs->ENSEMBL_SITETYPE,
    'ticket_name' => $self->generate_ticket_name,
    'job'         => [ map {
      'job_desc'    => delete $_->{'job_desc'} // '',
      'job_data'    => $_,
      'modified_at' => $now
    }, @$jobs ]
  });

  $ticket_type->save('changes_only' => 1);

  $self->submit_jobs_to_hive($ticket);
}

sub delete_ticket_or_job {
  ## Deletes a ticket (or just a job linked to a ticket) according to the URL params
  ## @return 1 if deleted successfully, undef if there was a problem
  my $self    = shift;
  my $params  = $self->parse_url_param;

  my ($ticket, $job);

  if ($params->{'job_id'}) {

    $job = $self->get_requested_job;

    if ($job) {
      $ticket = $job->ticket;
      $ticket = undef if $ticket->job_count > 1; # don't delete it if there are more jobs linked to it
    }

  } elsif ($params->{'ticket_name'}) {
    $ticket = $self->get_requested_ticket;
  }

  ## TODO - delete related hive job and work dir

  return 1 if $ticket && $ticket->delete;
  return 1 if $job && $job->delete;
}

sub submit_jobs_to_hive {
  ## Submits the jobs linked to a ticket to hive
  ## @param Ticket object
  my ($self, $ticket) = @_;

  my $hive_adaptor  = $self->hive_adaptor;
  my $job_adaptor   = $hive_adaptor->get_AnalysisJobAdaptor;
  my $hive_analysis = $hive_adaptor->get_AnalysisAdaptor->fetch_by_logic_name_or_url($ticket->ticket_type_name);

  foreach my $job ($ticket->job) {
    if (my $hive_job_data = $self->process_job_for_hive_submission($job)) {

      # add some generic params to job data to be submitted
      $hive_job_data->{'ticket_id'}   = $ticket->ticket_id;
      $hive_job_data->{'ticket_name'} = $ticket->ticket_name;
      $hive_job_data->{'job_id'}      = $job->job_id;

      # Submit job to hive
      my $hive_job_id = $job_adaptor->CreateNewJob(
        -input_id => $hive_job_data,
        -analysis => $hive_analysis,
      );

      if ($hive_job_id) {
        $job->hive_job_id($hive_job_id);
        $job->hive_job_data($hive_job_data); # TODO - Do we really need this?
        $job->status('awaiting_hive_response');
        $job->hive_status('queued');
      }
    }
    $job->save('changes_only' => 1); # only update if anything changed (process_job_for_hive_submission method may also have changed the job, so keep this outside the if statement)
  }
}

sub get_current_tickets {
  ## Gets (and caches) all the current tickets either for the logged in user or the session
  ## @return Arrayref of ticket objects
  my $self = shift;

  unless (exists $self->{'_current_tickets'}) {
    my $hub     = $self->hub;
    my $user    = $hub->user;
    my $action  = $hub->action;

    my $ticket_types  = $self->rose_manager(qw(Tools TicketType))->fetch_with_current_tickets({
      'site_type'       => $hub->species_defs->ENSEMBL_SITETYPE,
      'session_id'      => $hub->session->session_id, $user ? (
      'user_id'         => $user->user_id ) : (), $action && $action ne 'Summary' ? ( # 'Summary' page request is the only case where ticket_type() is not implemented
      'type'            => $self->ticket_type) : ()
    });

    my @tickets = map $_->ticket, @$ticket_types;
    $self->update_jobs_from_hive($_) for @tickets;
    $self->{'_current_tickets'} = \@tickets;
  }

  return $self->{'_current_tickets'};
}

sub get_requested_ticket {
  ## Gets a ticket object from the database with param from the URL and caches it for subsequent requests
  ## @return Ticket rose object, or undef if not found or if ticket does not belong to logged-in user or session
  my $self = shift;

  unless (exists $self->{'_requested_ticket'}) {
    my $hub         = $self->hub;
    my $user        = $hub->user;
    my $ticket_name = $self->parse_url_param->{'ticket_name'};
    my $ticket;

    if ($ticket_name) {
      my $ticket_type = $self->rose_manager(qw(Tools TicketType))->fetch_with_current_tickets({
        'site_type'     => $hub->species_defs->ENSEMBL_SITETYPE,
        'ticket_name'   => $ticket_name,
        'session_id'    => $hub->session->session_id, $user ? (
        'user_id'       => $user->user_id ) : ()
      });

      if (@$ticket_type) {
        $ticket = $ticket_type->[0]->ticket->[0];
        $self->update_jobs_from_hive($ticket);
      }
    }

    $self->{'_requested_ticket'} = $ticket;
  }

  return $self->{'_requested_ticket'};
}

sub update_jobs_from_hive {
  ## Updates jobs linked to the given ticket from the corresponding ones in the hive db
  ## @param Ticket object to which jobs are linked
  ## @return No return value
  my ($self, $ticket) = @_;

  foreach my $job ($ticket->job) {

    my $status = $job->status;

    if ($status eq 'awaiting_hive_response') {

      my $hive_job_id   = $job->hive_job_id;
      my $hive_adaptor  = $self->hive_adaptor;
      my $hive_job      = $hive_adaptor->get_AnalysisJobAdaptor->fetch_by_dbID($hive_job_id);

      if ($hive_job) {
        my $hive_job_status = $hive_job->status;

        if ($hive_job_status eq 'DONE') {

          # job is done, no more actions required
          $job->status('done');
          $job->hive_status('done');

        } elsif ($hive_job_status =~ /^(FAILED|PASSED_ON)$/) {

          # job failed due to some reason, need user to look into it
          $job->status('awaiting_user_response');
          $job->hive_status('failed');

          # Get the log message and save it in the message column
          my ($message) = map {$_->{'is_error'} && $_->{'msg'} || ()} @{$hive_adaptor->get_LogMessageAdaptor->fetch_all_by_job_id($hive_job_id)}; # ignore if msg is an empty string
          if ($message && $message =~ /^{.*}$/) { # possibly json
            try {
              $message = from_json($message);
            } catch {};
          }

          $job->job_message([ref $message
            ? {
              'display_message'   => delete $message->{'data'}{'display_message'} // $self->default_error_message,
              'fatal'             => delete $message->{'data'}{'not_fatal'} ? 0 : 1,
              'data'              => delete $message->{'data'},
              'exception'         => $message,
            }
            : {
              'display_message'   => $self->default_error_message,
              'exception'         => {'exception' => $message || 'Unknown error'},
              'fatal'             => 1
            }
          ]);

        } elsif ($hive_job_status =~ /^(SEMAPHORED|CLAIMED|COMPILATION)$/) {

          # job is just submitted to a queue
          $job->hive_status('submitted') if $job->hive_status ne 'submitted';

        } elsif ($hive_job_status =~ /^(PRE_CLEANUP|FETCH_INPUT|RUN|WRITE_OUTPUT|POST_CLEANUP)$/) {

          # job is still running, but keep an eye in it, so no need to change 'status', only set the 'hive_status' ('if' condition prevents an extra SQL query)
          $job->hive_status('running') if $job->hive_status ne 'running';

        } # for READY status, no need to change status or hive_status

      } else {

        # this will only get executed if the job got removed from the hive db's job table somehow (very unlikely though)
        $job->status('awaiting_user_response');
        $job->hive_status('deleted');
        $job->job_message([{'display_message' => 'Submitted job has got deleted from the queue.'}]);
      }

      # update if anything is changed
      $job->save('changes_only' => 1);
    }
  }
}

sub get_requested_job {
  ## Gets the job object according to the URL param
  ## @param Hashref with one of the following keys
  ##  - 'with_all_results'      Flag if on, will get all results linked to the job object
  ##  - 'with_requsted_result'  Flag if on, will only get the result object with ID in the URL 'tl' param
  ## @return Job object, or undef if no job found for the given id, or job doesn't belong to the logged in user or current session, or requested result doesn't belong to the job
  my ($self, $params) = @_;

  my $key = [ map { $params->{$_} ? "_requested_job_$_" : () } qw(with_all_results with_requested_result) ]->[0] || '_requested_job';

  unless (exists $self->{$key}) {
    my $hub         = $self->hub;
    my $user        = $hub->user;
    my $url_params  = $self->parse_url_param;
    my $job;

    if (my $job_id = $url_params->{'job_id'}) {

      my %results_key = $params->{'with_all_results'}
        ? ('result_id' => 'all')
        : ($params->{'with_requested_result'}
          ? ('result_id' => $url_params->{'result_id'})
          : ()
        );

      my $ticket_type = $self->rose_manager(qw(Tools TicketType))->fetch_with_given_job({
        'site_type'     => $hub->species_defs->ENSEMBL_SITETYPE,
        'ticket_name'   => $url_params->{'ticket_name'},
        'job_id'        => $job_id,
        'session_id'    => $hub->session->session_id, $user ? (
        'user_id'       => $user->user_id ) : (),
        'type'          => $self->ticket_type,
        %results_key
      });

      if ($ticket_type) {
        my $ticket = $ticket_type->ticket->[0];
        $self->update_jobs_from_hive($ticket); # this will only update the required job but not all jobs linked to the ticket since only one job was actually fetched by providing job_id
        $job = $ticket->job->[0];
      }
    }

    $self->{$key} = $job;
  }

  return $self->{$key};
}

sub get_time_now {
  # Gets the current time in a format that can be saved in the db
  my ($sec, $min, $hour, $day, $month, $year) = localtime;
  return sprintf '%d-%02d-%02d %02d:%02d:%02d', $year + 1900, $month + 1, $day, $hour, $min, $sec;
}

sub format_date { ## TODO ??? move to root?
  my ($self, $datetime) = @_;
  return unless $datetime;

  my @date = split(/-|T|:/, $datetime);
  $datetime = sprintf('%s/%s/%s, %s:%s',
    $date[2],
    $date[1],
    $date[0],
    $date[3],
    $date[4]
  );
  return $datetime;
}
1;
