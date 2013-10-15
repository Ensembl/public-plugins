package EnsEMBL::Web::Component::Tools::VEP::TicketsList;

use strict;
use warnings;

use base qw(
  EnsEMBL::Web::Component::Tools::TicketsList
  EnsEMBL::Web::Component::Tools::VEP
);

# override method since we only have one job per ticket for VEP
sub ticket_link {
  my $self = shift;
  my $ticket = shift;
  
  my $ticket_name = $ticket->ticket_name;
  my $object = $self->object;
  my $hub = $self->hub;
  
  my $job_id = ($ticket->job)[0]->job_id;
  
  return sprintf('<a href="%s">%s</a>', $hub->url({'action' => $ticket->ticket_type->ticket_type_name, 'function' => 'Summary', 'tl' => $object->create_url_param({'ticket_name' => $ticket_name, 'job_id' => $job_id})}), $ticket_name)
}

1;