package Bio::EnsEMBL::GlyphSet::contig;

use strict;

sub genoverse_attributes {
  return (
    id         => $_[1]{'name'},
    labelColor => '#FFFFFF',
  );
}

1;
