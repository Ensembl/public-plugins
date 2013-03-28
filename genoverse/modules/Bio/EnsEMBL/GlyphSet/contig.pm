package Bio::EnsEMBL::GlyphSet::contig;

use strict;

sub genoverse_attributes {
  my $slice_start = $_[0]{'container'}->start - 1;
  my $start       = $_[1]{'from_start'} + $slice_start;
  
  return (
    id         => "$_[1]{'name'}:$start",
    start      => $start,
    end        => $_[1]{'from_end'} + $slice_start,
    labelColor => '#FFFFFF',
  );
}

1;
