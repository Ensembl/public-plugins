=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::JSONServer::Tools::VEP;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::JSONServer::Tools);

sub object_type { 'VEP' }

# Used in species selector (Taxonselector)
sub json_fetch_species {
  my $self = shift;
  my $hub = $self->hub;
  $self->{species_selector_data} = $self->getSpeciesSelectorData();
  $self->{species_selector_data}->{internal_node_select} = 0;
  my @dyna_tree = $self->create_tree();
  return { json => \@dyna_tree };
}

1;