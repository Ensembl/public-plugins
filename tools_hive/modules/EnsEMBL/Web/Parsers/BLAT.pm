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

package EnsEMBL::Web::Parsers::BLAT;

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::Parsers::NCBIBLAST);

sub parse {
  my ($self, $file) = @_;
  my $runnable      = $self->runnable;
  my $species       = $runnable->param('species');
  my $source_type   = $runnable->param('source');
  my $configs       = $runnable->param_is_defined('configs') ? $runnable->param('configs') : {};

  my $max_evalue    = exists $configs->{'evalue'} ? sprintf("%.10g", $configs->{'evalue'}) : undef;
  my $max_target    = exists $configs->{'max_target_seqs'} ? $configs->{'max_target_seqs'} : undef;

  my @results       = file_get_contents($file, sub {

    chomp;

    my @hit_data  = split /\t/, $_;
    my $q_ori     = $hit_data[6] < $hit_data[7] ? 1 : -1;
    my $t_ori     = $hit_data[8] < $hit_data[9] ? 1 : -1;

    my $tstart    = $hit_data[8] < $hit_data[9] ? $hit_data[8] : $hit_data[9];
    my $tend      = $hit_data[8] < $hit_data[9] ? $hit_data[9] : $hit_data[8];

    return if defined $max_evalue && $max_evalue < sprintf("%.10g", $hit_data[10]);

    return {
      qid           => $hit_data[0],
      qstart        => $hit_data[6],
      qend          => $hit_data[7],
      qori          => $q_ori,
      tid           => $hit_data[1],
      tstart        => $tstart,
      tend          => $tend,
      tori          => $t_ori,
      score         => $hit_data[11],
      evalue        => $hit_data[10],
      pident        => $hit_data[2],
      len           => $hit_data[3],
      aln           => $hit_data[12],
    };
  });

  @results = sort { $a->{'evalue'} <=> $b->{'evalue'} } @results;
  @results = splice @results, 0, $max_target if defined $max_target && @results > $max_target;
  @results = map $self->map_to_genome($_, $species, $source_type), @results;

  $self->disconnect_dbc;

  return \@results;
}

1;
