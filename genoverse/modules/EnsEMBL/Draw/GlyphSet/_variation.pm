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

package EnsEMBL::Draw::GlyphSet::_variation;

use strict;

use Bio::EnsEMBL::Variation::Utils::Constants;

use previous qw(depth);

sub _labels              { return $_[0]{'_labels'} ||= { map { $_->SO_term => $_->label } values %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES }; }
sub genoverse_attributes { return ( legend => $_[0]->_labels->{$_[1]->display_consequence}, id => $_[1]->dbID ); }
sub depth                { return $_[0]->PREV::depth if $_[0]{'container'}; }
sub scalex               { return $_[0]{'config'}->transform_object ? $_[0]{'config'}->transform_object->scalex : 1; }

1;
