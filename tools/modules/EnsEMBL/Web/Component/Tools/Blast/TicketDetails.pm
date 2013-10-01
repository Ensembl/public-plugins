package EnsEMBL::Web::Component::Tools::Blast::TicketDetails;

use strict;
use warnings;

use base qw(
  EnsEMBL::Web::Component::Tools::TicketDetails
  EnsEMBL::Web::Component::Tools::Blast
);

sub content_ticket {
  my ($self, $ticket) = @_;
  my $hub     = $self->hub;
  my $div     = $self->dom->create_element('div');

  $div->append_child($self->job_details_table($_, {'links' => [qw(results edit delete)]}))->set_attribute('class', 'plain-box') for $ticket->job;

  return $div->render;
}

1;