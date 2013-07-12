package Bio::EnsEMBL::GlyphSet::fg_segmentation_features;

use strict;

sub _labels              { return $_[0]{'_labels'} ||= $_[0]->my_config('colours'); }
sub genoverse_attributes { return ( legend => $_[0]->_labels->{$_[0]->colour_key($_[1])}{'text'} ); }

1;