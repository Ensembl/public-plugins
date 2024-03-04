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

package EnsEMBL::Web::Template::Legacy::Static;

### Overriding method to pass all species list as a hidden element to the page

use strict;
use previous qw(add_body);

sub add_body {
  my $self = shift;
  $self->PREV::add_body();
  $self->page->add_body_elements(qw(
    hidden_species_list EnsEMBL::Web::Document::Element::HiddenSpeciesList
  ));
}

1;
