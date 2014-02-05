=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::TicketDetails;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools);

use EnsEMBL::Web::Exceptions;

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $ticket  = ($hub->function || '') eq 'View' ? $object->get_requested_ticket : undef;
  my $jobs    = $ticket ? [ $object->get_requested_job || () ] : [];
     $jobs    = $ticket->job if $ticket && !@$jobs;

  return sprintf '<input type="hidden" class="panel_type" value="TicketDetails" />%s', ($ticket
    ? sprintf(q(<h3>Job%s for %s ticket %s<a href="%s" class="left-margin _ticket_hide small _change_location">[Hide]</a></h3>%s),
      @$jobs > 1 ? 's' : '',
      $ticket->ticket_type->ticket_type_caption,
      $ticket->ticket_name,
      $hub->url({'tl' => undef, 'function' => ''}),
      $self->content_ticket($ticket, $jobs)
    )
    : ''
  );
}

sub content_ticket {
  ## @abstract method
  ## Should return disaply html for the ticket
  throw exception('AbstractMethodNotImplemented');
}

1;
