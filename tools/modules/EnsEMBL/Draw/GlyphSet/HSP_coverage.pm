=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use parent qw(EnsEMBL::Draw::GlyphSet);

sub _init {
  my $self          = shift;
  my $container     = $self->{'container'};
  my $config        = $self->{'config'};
  my $sample_size   = int($container->length() / 1000) || 1;
  my @all_hsps      = sort {$a->{'qstart'} <=> $b->{'qstart'} || $a->{'qend'} <=> $b->{'qend'} } @{$container->hsps};
  my $distribution  = {};

  return if scalar @all_hsps < 2;

  foreach my $hsp (@all_hsps) {
    my $sample_sskip = $hsp->{'qstart'} % $sample_size;
    my $sample_start = $hsp->{'qstart'} - $sample_sskip;
    my $sample_eskip = $hsp->{'qend'}   % $sample_size;
    my $sample_end   = $hsp->{'qend'};
    $sample_end     += $sample_size if $sample_eskip != 0;

    for (my $i = $sample_start; $i <= $sample_end; $i += $sample_size) {
      for (my $j = $i; $j < $i + $sample_size; $j++) {
        $distribution->{$i}++;
      }
    }
  }
  my ($max) = sort {$b <=> $a} values %$distribution;

  return if $max == 0;

  my $smax = 50;

  while(my ($pos, $val) = each %$distribution) {
    my $sval   = $smax * $val / $max;

    $self->push($self->Rect({
      'x'      => $pos,
      'y'      => $smax/3 - $sval/3,
      'width'  => $sample_size,
      'height' => $sval/3,
      'colour' => $val == $max ? 'grey20' : 'grey'.int(100 - $sval)
    }));
  }

  $self->push($self->Rect({
    'x'      => 0,
    'y'      => $smax/3,
    'width'  => $container->length,
    'height' => 0,
    'colour' => 'white',
  }));
}

1;
