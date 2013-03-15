package Bio::EnsEMBL::GlyphSet::_variation;

use strict;

sub genoverse_attributes { return ( legend => $_[0]->my_colour($_[0]->colour_key($_[1]), 'text') ); }

1;
