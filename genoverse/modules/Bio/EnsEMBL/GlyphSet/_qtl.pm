package Bio::EnsEMBL::GlyphSet::_qtl;

use strict;

sub genoverse_attributes {
  my ($self, $f) = @_;
  
  return (
    id    => $f->qtl->dbID,
    title => $self->title($f)
  );
}

1;
