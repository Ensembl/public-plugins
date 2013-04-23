package Bio::EnsEMBL::GlyphSet::_variation;

use strict;

use EnsEMBL::Web::Tools::MethodMaker(copy => [ 'depth', '_depth' ]);

sub genoverse_attributes { return ( legend => $_[0]->my_colour($_[0]->colour_key($_[1]), 'text') ); }
sub depth                { return $_[0]->_depth if $_[0]{'container'}; }
sub scalex               { return $_[0]{'config'}{'transform'} ? $_[0]->SUPER::scalex : 1; }

1;
