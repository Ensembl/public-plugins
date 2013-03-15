package Bio::EnsEMBL::GlyphSet::structural_variation;

use strict;

sub genoverse_attributes { return $_[1]->is_somatic && $_[1]->breakpoint_order ? ( breakpoint => 1, height => 12, spacing => 9, color => 'transparent' ) : (); }

1;
