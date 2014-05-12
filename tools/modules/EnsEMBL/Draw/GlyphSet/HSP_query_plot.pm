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

package EnsEMBL::Draw::GlyphSet::HSP_query_plot;

use strict;
use warnings;

use Sanger::Graphics::Bump;

use parent qw(EnsEMBL::Draw::GlyphSet);

sub _init {
  my ($self)        = @_;
  my $container     = $self->{'container'};
  my $config        = $self->{'config'};
  my $mode          = $self->my_config('mode') || "byhit";
  my $colours       = $container->colours;
  my $opts          = {
    'pix_per_bp'      => $config->transform->{'scalex'},
    'bitmap_length'   => int($container->length() * $config->transform->{'scalex'}),
    'id'              => $container->name,
    'db'              => $container->{'database'},
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

  $self->hsp($_, $opts, $colours) for sort { $b->{'pident'} <=> $a->{'pident'} } @all_hsps;
}

sub hsp {
  my ($self, $hsp, $opts, $colours) = @_;

  my ($hspstart, $hspend) = $self->region($hsp);
  my $colour              = $colours->[int(((@$colours - 1) * $hsp->{'pident'} / 100) + 0.5)]; # round
  my $height              = 5;
  my $glyph               = Sanger::Graphics::Glyph::Rect->new({
    'x'                     => $hspstart,
    'y'                     => 0,
    'width'                 => $hspend - $hspstart,
    'height'                => $height,
    'colour'                => $colour,
    'bordercolour'          => 'black',
    'href'                  => $self->_url({
      'species' => $self->species,
      'action'  => 'Blast',
      'tl'      => $hsp->{'tl'}
    })
  });

  my $bump_start          = int($glyph->x() * $opts->{'pix_per_bp'});
     $bump_start          = 0 if $bump_start < 0;
  my $bump_end            = $bump_start + int($glyph->width() * $opts->{'pix_per_bp'}) + 1;
     $bump_end            = $opts->{'bitmap_length'} if $bump_end > $opts->{'bitmap_length'};
  my $row                 = &Sanger::Graphics::Bump::bump_row($bump_start, $bump_end, $opts->{'bitmap_length'}, $opts->{'bitmap'});

  return if $opts->{'dep'} != 0 && $row >= $opts->{'dep'};
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
