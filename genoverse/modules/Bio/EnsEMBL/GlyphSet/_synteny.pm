package Bio::EnsEMBL::GlyphSet::_synteny;

use strict;

sub genoverse_attributes {
  my ($self, $f) = @_;
  
  return (
    id      => join(':', map $f->{$_}, qw(hit_chr_name hit_chr_start hit_chr_end)),
    colorId => $f->{'hit_chr_name'}
  );
}

1;
