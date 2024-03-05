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

package EnsEMBL::Web::Document::Element::HiddenSpeciesList;

### Create a hidden element to pass all species list as a string joined by '|'
### Currently being used by Google Analytics

use strict;
use parent qw(EnsEMBL::Web::Document::Element);

sub content {
  my $self = shift;
  my $html = '';
  my $species_defs = $self->species_defs;
  my $val = join '|', $self->species_defs->valid_species;
  return qq (<input type="hidden" id="hidden_species_list" name="hidden_species_list" value=$val>);
}

1;
