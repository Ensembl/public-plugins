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

use parent qw(EnsEMBL::Web::Component::Tools);

use EnsEMBL::Web::Exceptions;

sub content {
  my $self      = shift;
  my $object    = $self->object;
  my $hub       = $self->hub;
  my $function  = $hub->function || '';
  my $ticket    = grep({ $function eq $_ } $self->allowed_url_functions) ? $object->get_requested_ticket : undef;
  my $jobs      = $ticket ? [ $object->get_requested_job || () ] : [];
     $jobs      = $ticket->job if $ticket && !@$jobs;
  my $is_view   = $function eq 'View';

  my $heading = $is_view
    ? sprintf('<h3>Job%s for %s ticket %s<a href="%s" class="left-margin _ticket_hide small _change_location">[Hide]</a></h3>',
        @$jobs > 1 ? 's' : '',
        $ticket->ticket_type->ticket_type_caption,
        $ticket->ticket_name,
        $is_view ? $hub->url({'tl' => undef, 'function' => ''}) : '',
      )
    : '<h3><a rel="_ticket_details" class="toggle _slide_toggle closed" href="#">Job details</a></h3>';

  return sprintf '<input type="hidden" class="panel_type" value="TicketDetails" />%s%s', $ticket ? ($heading, $self->content_ticket($ticket, $jobs)) : ('', '');
}

sub content_ticket {
  ## @abstract method
  ## Should return disaply html for the ticket
  throw exception('AbstractMethodNotImplemented');
}

sub allowed_url_functions {
  ## List of url function that can display ticket details (this is to enable dynamic behaviour of displaying ticket details)
  return qw(View);
}

1;
