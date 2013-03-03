package EnsEMBL::Web::Factory::Tools;


use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Factory);
use EnsEMBL::Web::Object::Tools;
use EnsEMBL::ORM::Rose::Manager::Ticket;

sub createObjects {
  my $self = shift;
  my $tools = shift;
  my $tk;

  my $tools_object = $self->DataObjects($self->new_object('Tools', {}, $self->__data));

  $tk = $self->param('tk');
  if ($tk) {
    my $manager = $self->dynamic_use_fallback("EnsEMBL::ORM::Rose::Manager::Ticket");

    my $ticket_object = shift @{$manager->fetch_by_ticket_name($tk)};
    $self->DataObjects($self->new_object('Tools', {'_ticket' => $ticket_object} , $self->__data));
  } 
}


=cut
sub createObjects {
  my $self = shift;

  return $self->DataObjects($self->new_object(
    'Tools',
    {},
    $self->__data )
  );

}
=cut
1;
