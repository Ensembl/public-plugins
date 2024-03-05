=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Draw::GlyphSet::HSP_coverage;

use strict;
use warnings;

use POSIX;

use parent qw(EnsEMBL::Draw::GlyphSet);

sub _init {
  my $self          = shift;
  my $container     = $self->{'container'};
  my $config        = $self->{'config'};
  my $sample_size   = int($container->length / 1000) || 1;
  my $all_hsps      = $container->hsps;
  my $track_height  = 2 * scalar @$all_hsps;
     $track_height  = 20 if $track_height > 20;
  my $distribution  = {};
  my @coords;

  foreach my $hsp (@$all_hsps) {

    my ($start, $end) = $self->region($hsp);

    $start = floor($start / $sample_size) || 1;
    $end   = ceil($end / $sample_size);

    $distribution->{$_}++ for $start .. $end;
  }

  my ($max)     = sort {$b <=> $a} values %$distribution;
  my ($max_key) = sort {$b <=> $a} keys %$distribution;
  my ($min_key) = sort {$a <=> $b} keys %$distribution;

  return if $max == 0;

  # convert the distribution to drawing coords
  for ($min_key .. $max_key) {
    if (@coords && $coords[-1]{'h'} == ($distribution->{$_} || 0)) {
      $coords[-1]{'w'} += 1;
    } else {
      push @coords, { 'h' => $distribution->{$_} || 0, 'w' => 1, 'x' => @coords ? $coords[-1]{'w'} + $coords[-1]{'x'} : $min_key - 1};
    }
  }

  for (sort { $a->{'h'} <=> $b->{'h'} } @coords) { # draw the tallest ones in the end to fix the pixel-overlap issue
    my $height = $track_height * $_->{'h'} / $max;
    $self->push($self->Rect({
      'x'      => $_->{'x'} * $sample_size,
      'y'      => $track_height - $height,
      'width'  => $_->{'w'} * $sample_size,
      'height' => $height,
      'colour' => sprintf 'grey%s', $_->{'h'} == $max ? 20 : int(100 - 50 * $_->{'h'} / $max)
    }));
  }
}

sub region {
  my ($self, $hsp) = @_;
  my $start = $hsp->{'qstart'};
  my $end   = $hsp->{'qend'};
  return $end < $start ? ($end, $start) : ($start, $end);
}

1;
