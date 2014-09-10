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

package EnsEMBL::Draw::GlyphSet::fg_regulatory_features;

use strict;

sub _labels { return $_[0]{'_labels'} ||= $_[0]->my_config('colours'); }

sub genoverse_attributes {
  my ($start, $end) = $_[0]->slice2sr($_[1]->bound_start, $_[1]->bound_end);
  return ( group => 1, bumpStart => $start, bumpEnd => $end, legend => $_[0]->_labels->{$_[0]->colour_key($_[1])}{'text'}, id => $_[1]->dbID );
}

1;