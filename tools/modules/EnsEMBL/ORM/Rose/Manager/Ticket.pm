package EnsEMBL::ORM::Rose::Manager::Ticket;

### NAME: EnsEMBL::ORM::Rose::Manager::Ticket
### Module to handle multiple Ticket entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Ticket objects

use base qw(EnsEMBL::ORM::Rose::Manager);

__PACKAGE__->make_manager_methods('tickets'); ## Auto-generate query methods: get_tickets, count_tickets, etc

sub object_class { 'EnsEMBL::ORM::Rose::Object::Ticket' };


#Data mining methods 
sub fetch_by_ticket_name {
  my ($self, $ticket_name) = @_;
  return undef unless $ticket_name;

  my $ticket = $self->get_tickets(
    with_objects => ['job'],
    query => ['ticket_name' => $ticket_name ]
  );
  return $ticket;
}

sub fetch_all_tickets_by_user {
  my ($self, $user_id) = @_;
  return undef unless $user_id;

  $user_id = 'user_' .$user_id;
  my $user_tickets =  $self->get_tickets(
    with_objects => ['job'],
    query => ['owner_id' => $user_id ]
  );
  return $user_tickets;
}

sub fetch_all_tickets_by_session {
  my ($self, $session_id) = @_;
  return undef unless $session_id;

  $session_id = 'session_' .$session_id;
  my $session_tickets =  $self->get_tickets(
    query => ['owner_id' => $session_id ]
  );
  return $session_tickets;
}

1;

