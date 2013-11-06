package Bio::EnsEMBL::GlyphSet::_variation;

use strict;

use Bio::EnsEMBL::Variation::Utils::Constants;

use previous qw(depth);

sub _labels              { return $_[0]{'_labels'} ||= { map { $_->SO_term => $_->label } values %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES }; }
sub genoverse_attributes { return ( legend => $_[0]->_labels->{$_[1]->display_consequence} ); }
sub depth                { return $_[0]->PREV::depth if $_[0]{'container'}; }
sub scalex               { return $_[0]{'config'}{'transform'} ? $_[0]->SUPER::scalex : 1; }

1;
