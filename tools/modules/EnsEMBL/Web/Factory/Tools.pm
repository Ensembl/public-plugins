package EnsEMBL::Web::Factory::Tools;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

use ORM::EnsEMBL::DB::Tools::Manager::Ticket;

sub createObjects {
  my $self        = shift;
  my $data        = $self->__data;
  my $ticket_name = $self->param('tk');
  my $tools_data  = $ticket_name ? {'_ticket' => ORM::EnsEMBL::DB::Tools::Manager::Ticket->fetch_ticket_by_name($ticket_name)} : {};

  $self->DataObjects($self->new_object($self->hub->action || 'Tools', $tools_data, $data) || $self->new_object('Tools', $tools_data, $data));
}

1;
