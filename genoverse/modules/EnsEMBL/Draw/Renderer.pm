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

package EnsEMBL::Draw::Renderer;

use strict;
use warnings;

use previous qw(add_location_marking_layer);

sub add_location_marking_layer {
  my ($self, $coords) = @_;

  if ($coords) {

    $coords->{'y'} //= 0;
    $coords->{'h'} //= $self->{'im_height'} || $self->{'image_height'} || $self->{'canvas'}{'im_height'};

    return $self->PREV::add_location_marking_layer($coords);
  }
}

1;
