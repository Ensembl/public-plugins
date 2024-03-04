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

package EnsEMBL::Draw::GlyphSet::BlastHitLegend;

use strict;
use warnings;

use EnsEMBL::Web::BlastConstants qw(BLAST_KARYOTYPE_POINTER);

use parent qw(EnsEMBL::Draw::GlyphSet::legend);

sub _init {
  my $self      = shift;
  my $colourmap = $self->{'config'}->hub->colourmap;
  my $pattern   = $self->{'my_config'}->data->{'pattern'};

  $self->init_legend(2);

  $self->add_to_legend({
    'legend' => '% ID on blast hits (selected job)',
    'colour' => [ $colourmap->build_linear_gradient(@{BLAST_KARYOTYPE_POINTER->{'gradient'}}) ],
    'stripe' => $pattern,
  });

  $self->add_to_legend({
    'legend' => '% ID on blast hits (other jobs in this region)',
    'colour' => [ $colourmap->build_linear_gradient(@{BLAST_KARYOTYPE_POINTER->{'gradient_others'}}) ],
    'stripe' => $pattern,
  });

}

1;
