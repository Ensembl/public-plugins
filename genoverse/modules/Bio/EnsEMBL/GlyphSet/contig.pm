package Bio::EnsEMBL::GlyphSet::contig;

use strict;

sub genoverse_attributes {
  return (
    id         => "$_[1]{'name'}:$_[1]{'start'}",
    labelColor => '#FFFFFF',
  );
}


1;
