package Bio::EnsEMBL::GlyphSet::fg_regulatory_features;

use strict;

sub _labels { return $_[0]{'_labels'} ||= $_[0]->my_config('colours'); }

sub genoverse_attributes {
  my ($start, $end) = $_[0]->slice2sr($_[1]->bound_start, $_[1]->bound_end);
  return ( group => 1, bumpStart => $start, bumpEnd => $end, legend => $_[0]->_labels->{$_[0]->colour_key($_[1])}{'text'} );
}

1;