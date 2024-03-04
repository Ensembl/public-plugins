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

package EnsEMBL::Web::Configuration::Variation;

use strict;

sub modify_tree {
  my $self   = shift;

  ## Hide this node if not configured, as it's external data
  my $external = $self->get_node('ExternalData');
  if ($external && $self->hub->species_defs->LOVD_URL) {
    $external->append($self->create_node('LOVD', 'LOVD',
      [qw( lovd EnsEMBL::Web::Component::Variation::LOVD )],
      { 'availability' => 1 }
    ));
  }

}

1;
