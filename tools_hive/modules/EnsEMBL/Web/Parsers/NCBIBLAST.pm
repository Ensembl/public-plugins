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

package EnsEMBL::Web::Parsers::NCBIBLAST;

use strict;
use warnings;

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::Parsers);

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'dba'} = Bio::EnsEMBL::DBSQL::DBAdaptor->new(%{$self->runnable->param('dba')});
  return $self;
}

sub disconnect_dbc {
  my $self = shift;
  $self->{'dba'}->dbc->disconnect_if_idle;
}

sub get_adapter {
  my ($self, $feature_type) = @_;
  return $self->{"_adaptor_$feature_type"} ||= $self->{'dba'}->get_adaptor($feature_type);
}

sub parse {
  my ($self, $file) = @_;
  my $runnable      = $self->runnable;
  my $species       = $runnable->param('species');
  my $source_type   = $runnable->param('source');
  my $max_hits      = $runnable->param('__max_hits');

  my @results       = file_get_contents($file, sub {

    chomp;

    my @hit_data  = split /\t/, $_;
    my $q_ori     = $hit_data[1] < $hit_data[2] ? 1 : -1;
    my $t_ori     = $hit_data[4] < $hit_data[5] ? 1 : -1;

    my $tstart    = $hit_data[4] < $hit_data[5] ? $hit_data[4] : $hit_data[5];
    my $tend      = $hit_data[4] < $hit_data[5] ? $hit_data[5] : $hit_data[4];

    return {
      qid           => $hit_data[0],
      qstart        => $hit_data[1],
      qend          => $hit_data[2],
      qori          => $q_ori,
      qframe        => $hit_data[11],
      tid           => $hit_data[3] =~ s/\..+//r, # without any version info
      v_tid         => $hit_data[3],              # possibly versioned
      tstart        => $tstart,
      tend          => $tend,
      tori          => $t_ori,
      tframe        => $hit_data[12],
      score         => $hit_data[6],
      evalue        => $hit_data[7],
      pident        => $hit_data[8],
      len           => $hit_data[9],
      aln           => $hit_data[10],
    };
  });

  @results = sort { $a->{'evalue'} <=> $b->{'evalue'} } @results;
  @results = splice @results, 0, $max_hits if $max_hits && @results > $max_hits; # only keep the requested number of hits
  @results = map $self->map_to_genome($_, $species, $source_type), @results;

  $self->disconnect_dbc;

  return \@results;
}

sub map_to_genome {
  my ($self, $hit, $species, $source_type) = @_;

  my ($g_id, $g_start, $g_end, $g_ori, $g_coords, $feature_type);

  if ($source_type =~/LATESTGP/) {

    $g_id     = $hit->{'tid'};
    $g_start  = $hit->{'tstart'};
    $g_end    = $hit->{'tend'};
    $g_ori    = $hit->{'tori'};

  } else {

    $feature_type     = $source_type =~ /abinitio/i ? 'PredictionTranscript' : $source_type =~ /pep/i ? 'Translation' : 'Transcript';
    my $mapper        = $source_type =~ /pep/i ? 'pep2genomic' : 'cdna2genomic';
    my $adaptor       = $self->get_adapter($feature_type);

    # if object is not found against un-versioned id, try the one which looked like versioned and retain it as tid if object is found
    my $object;
    $object = $adaptor->fetch_by_stable_id($_) and $hit->{'tid'} = $_ and last for $hit->{'tid'}, $hit->{'v_tid'};

    if ($object) {

      $object     = $object->transcript if $feature_type eq 'Translation';
      my @coords  = sort { $a->start <=> $b->start } grep { !$_->isa('Bio::EnsEMBL::Mapper::Gap') } $object->$mapper($hit->{'tstart'}, $hit->{'tend'});
      $g_id       = $object->seq_region_name;
      $g_start    = $coords[0]->start;
      $g_end      = $coords[-1]->end;
      $g_ori      = $object->strand;
      $g_coords   = \@coords;

    } else {

      $g_id       = 'Unmapped';
      $g_start    = 'N/A';
      $g_end      = 'N/A';
      $g_ori      = 'N/A'

    }
  }

  delete $hit->{'v_tid'} if $feature_type && $feature_type ne 'Transcript'; # we need versioning for transcript only

  $hit->{'gid'}       = $g_id;
  $hit->{'gstart'}    = $g_start;
  $hit->{'gend'}      = $g_end;
  $hit->{'gori'}      = $g_ori;
  $hit->{'species'}   = $species;
  $hit->{'source'}    = $source_type;
  $hit->{'g_coords'}  = $g_coords if $g_coords;

  return $hit;
}

1;
