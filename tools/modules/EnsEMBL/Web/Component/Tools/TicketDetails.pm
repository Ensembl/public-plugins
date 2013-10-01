package EnsEMBL::Web::Component::Tools::TicketDetails;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools);

use EnsEMBL::Web::Exceptions;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $ticket  = $object->get_requested_ticket;

  return $ticket
    ? sprintf(q(<h3>Job%s for %s ticket %s</h3>%s), @{$ticket->job} > 1 ? 's' : '', $ticket->ticket_type->ticket_type_caption, $ticket->ticket_name, $self->content_ticket($ticket))
    : sprintf(q(<p>Ticket with name '%s' could not be found.</p>), $hub->param('tk'))
  ;
}

sub content_ticket {
  ## @abstract method
  ## Should return disaply html for the ticket
  throw exception('AbstractMethodNotImplemented');
}

1;
