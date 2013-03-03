package Bio::EnsEMBL::GlyphSet::HSP_coverage;

use strict;

use Sanger::Graphics::Bump;

use base qw(Bio::EnsEMBL::GlyphSet);

sub _init {
  my ($self)       = @_;
  my $container    = $self->{'container'};
  my $config       = $self->{'config'};
  my $sample_size  = int($container->length() / 1000) || 1;
  my @all_hsps     = $container->hsps;
  my $distribution = {};

  return if(scalar @all_hsps < 2);

  @all_hsps = sort {$a->{'qstart'} <=> $b->{'qstart'} || $a->{'qend'} <=> $b->{'qend'} } @all_hsps;

  foreach my $hsp (@all_hsps) {
    my $sample_sskip = $hsp->{'qstart'} % $sample_size;
    my $sample_start = $hsp->{'qstart'} - $sample_sskip;
    my $sample_eskip = $hsp->{'qend'}   % $sample_size;
    my $sample_end   = $hsp->{'qend'};
    $sample_end     += $sample_size if($sample_eskip != 0);

    for (my $i = $sample_start; $i <= $sample_end; $i+=$sample_size) {
      for (my $j = $i; $j<$i+$sample_size; $j++) {
        $distribution->{$i}++;
      }
    }
  }
  my $max = (sort {$b <=> $a} values %$distribution)[0];

  return if($max == 0);

  my $smax = 50;

  while(my ($pos, $val) = each %$distribution) {
    my $sval   = $smax * $val / $max;

    $self->push($self->Rect({
      'x'      => $pos,
      'y'      => $smax/3 - $sval/3,
      'width'  => $sample_size,
      'height' => $sval/3,
      'colour' => $val == $max ? 'red' : 'grey'.int(100 - $sval),
      'href'   => $self->href()  
  }));
  }

  $self->push($self->Rect({
    'x'      => 0,
    'y'      => $smax/3,
    'width'  => $container->length(),
    'height' => 0,
    'colour' => "white",
  }));
}

sub href {
  my ( $self, $hsp, $type ) = @_;


  my $href = $self->_url({
    'species' => $self->species,
    'type'    => 'Blast',
  });

  return $href;
}

1;

