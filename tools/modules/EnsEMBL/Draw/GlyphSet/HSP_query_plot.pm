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

package EnsEMBL::Draw::GlyphSet::HSP_query_plot;

use strict;
use warnings;

use EnsEMBL::Draw::Utils::Bump;

use parent qw(EnsEMBL::Draw::GlyphSet);

sub _init {
  my ($self)        = @_;
  my $container     = $self->{'container'};
  my $config        = $self->{'config'};
  my $mode          = $self->my_config('mode') || "byhit";
  my $colours       = $container->colours;
  my $options       = {
    'pix_per_bp'      => $config->transform_object->scalex,
    'bitmap_length'   => int($container->length() * $config->transform_object->scalex),
    'id'              => $container->name,
    'dep'             => $self->my_config('dep') || 10,
    'bitmap'          => [],
    'tally'           => {},
  };

  my @all_hsps      = ();
  my $ori           = $self->strand;

  foreach my $hsp (@{$container->hsps}) {
    my $qori = $hsp->{'q_ori'} || 1;
    my $hori = $hsp->{'g_ori'} || 1;
    next if $qori * $hori != $ori;
    push @all_hsps, $hsp;
  }

  $self->hsp($_, $options, $colours) for sort { $a->{'pident'} <=> $b->{'pident'} } @all_hsps;
}

sub hsp {
  my ($self, $hsp, $options, $colours) = @_;

  my ($start, $end) = $self->region($hsp);
  my $colour        = $colours->[int(((@$colours - 1) * $hsp->{'pident'} / 100) + 0.5)]; # round
  my $height        = 7;
  my $glyph         = $self->Rect({
    'x'               => $start - 1,
    'y'               => 0,
    'width'           => $end - $start + 1,
    'height'          => $height,
    'colour'          => $colour,
    'href'            => $self->_url({
      'species'         => $self->species,
      'type'            => 'Tools',
      'action'          => 'Blast',
      'function'        => '',
      'tl'              => $hsp->{'tl'},
      'hit'             => $hsp->{'result_id'},
    })
  });

  my $bump_start          = int($glyph->x() * $options->{'pix_per_bp'});
     $bump_start          = 0 if $bump_start < 0;
  my $bump_end            = $bump_start + int($glyph->width() * $options->{'pix_per_bp'}) + 1;
     $bump_end            = $options->{'bitmap_length'} if $bump_end > $options->{'bitmap_length'};
  my $row                 = &EnsEMBL::Draw::Utils::Bump::bump_row($bump_start, $bump_end, $options->{'bitmap_length'}, $options->{'bitmap'});

  return if $options->{'dep'} != 0 && $row >= $options->{'dep'};
  $glyph->y($glyph->y() - (1.6 * $row * $height * $self->strand()));
  $self->push($glyph);
}

sub region {
  my ($self, $hsp) = @_;
  my $start = $hsp->{'qstart'};
  my $end   = $hsp->{'qend'};
  return $end < $start ? ($end, $start) : ($start, $end);
}

1;
