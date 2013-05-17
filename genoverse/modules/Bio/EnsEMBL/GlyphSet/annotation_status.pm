package Bio::EnsEMBL::GlyphSet::annotation_status;

use strict;

sub genoverse_attributes {
  my ($self, $f) = @_;
  return ( strand => 1, background => $self->{'config'}->colourmap->hex_by_name($self->my_colour($self->colour_key($f), 'join')) );
}

1;
