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

package EnsEMBL::Draw::GlyphSet::fg_regulatory_features;

use strict;

sub _labels { return $_[0]{'_labels'} ||= $_[0]->my_config('colours'); }

sub genoverse_attributes {
  my ($self, $f) = @_;
  my ($bound_start, $bound_end) = $f->{'extra_blocks'} ? ($f->{'extra_blocks'}[0]{'start'}, $f->{'extra_blocks'}[1]{'end'}) 
                                                       : ($f->{'start'}, $f->{'end'});
  my ($start, $end) = $self->slice2sr($bound_start, $bound_end);
  return ( group => 1, bumpStart => $start, bumpEnd => $end, id => sprintf('regbuild_%s_%s', $start, $end));
}

1;
