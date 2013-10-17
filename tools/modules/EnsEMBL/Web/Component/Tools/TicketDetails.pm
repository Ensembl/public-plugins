package EnsEMBL::Web::Component::Tools::TicketDetails;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools);

use EnsEMBL::Web::Exceptions;

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $ticket  = $object->get_requested_ticket;

  return $ticket
    ? sprintf(q(<h3>Job%s for %s ticket %s</h3>%s), @{$ticket->job} > 1 ? 's' : '', $ticket->ticket_type->ticket_type_caption, $ticket->ticket_name, $self->content_ticket($ticket))
    : ($hub->param('tl') ? sprintf(q(<p>Requested ticket could not be found.</p>)) : '')
  ;
}

sub content_ticket {
  ## @abstract method
  ## Should return disaply html for the ticket
  throw exception('AbstractMethodNotImplemented');
}

1;
