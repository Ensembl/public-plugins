=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::FileChameleon::TicketsList;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::FileChameleon
  EnsEMBL::Web::Component::Tools::TicketsList
);

sub job_status_tag {
  ## @override
  ## Remove link from the status tag of finished jobs
  my $self    = shift;
  my $status  = $_[1];
  my $tag     = $self->SUPER::job_status_tag(@_);

  if ($status eq 'done') {
    $tag->{'title'} = q(This job is finished. Please click on the 'Download&nbsp;results' link to download result file.);
    $tag->{'href'}  = '';
  }

  return $tag;
}

1;
