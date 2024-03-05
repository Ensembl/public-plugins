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

package EnsEMBL::Draw::GlyphSet::structural_variation;

use strict;

use previous qw(depth);

use Bio::EnsEMBL::Variation::Utils::Constants;

sub _labels { return $_[0]{'_labels'} ||= \%Bio::EnsEMBL::Variation::Utils::Constants::VARIATION_CLASSES; }
sub depth   { return $_[0]->PREV::depth if $_[0]{'container'}; }

sub genoverse_attributes { 
  my ($self, $f) = @_;
  my %attrs = $self->{'display'} ne 'compact' && $f->is_somatic && $f->breakpoint_order ? ( breakpoint => 1, height => 12, marginRight => 9 ) : ();
  $attrs{'legend'} = $self->_labels->{$self->colour_key($f)}{'display_term'};
  $attrs{'id'}     = $f->dbID;
  return %attrs;
}

1;
