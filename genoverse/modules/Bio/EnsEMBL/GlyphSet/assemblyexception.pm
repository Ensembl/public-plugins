package Bio::EnsEMBL::GlyphSet::assemblyexception;

use strict;

sub genoverse_attributes {
  my ($self, $f) = @_;
  return ( background => $self->{'config'}->colourmap->hex_by_name($self->my_colour($self->colour_key($f), 'join')) );
}

1;
