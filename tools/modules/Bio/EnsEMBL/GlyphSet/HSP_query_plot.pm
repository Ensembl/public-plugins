package Bio::EnsEMBL::GlyphSet::HSP_query_plot;

use strict;

use base qw(Bio::EnsEMBL::GlyphSet::HSP_plot);

sub region {
  my ($self, $hsp) = @_;

  my $start = $hsp->{'qstart'};
  my $end   = $hsp->{'qend'};
  return ($start, $end);
}

1;
