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

package EnsEMBL::Web::Component::Tools::VEP::TicketDetails;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::VEP
  EnsEMBL::Web::Component::Tools::TicketDetails
);

sub content_ticket {
  my ($self, $ticket, $jobs) = @_;
  my $hub     = $self->hub;
  my $is_view = ($hub->function || '') eq 'View';
  my $table;

  for (@$jobs) {
    $table = $self->job_details_table($_, [$is_view ? qw(status results) : (), qw(edit delete)]);
    $table->set_attribute('class', $is_view ? 'plain-box' : 'toggleable hidden _ticket_details');
  }

  return $table ? $table->render : '';
}

1;
