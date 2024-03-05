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

package EnsEMBL::Web::Component::Tools::Blast::Alignment;

use strict;

use parent qw(EnsEMBL::Web::Component::Tools::Blast::TextSequence);

use EnsEMBL::Web::TextSequence::View::Alignment;
use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::MappedSlice;
use Bio::EnsEMBL::MappedSliceContainer;
use Bio::EnsEMBL::Mapper;
use Bio::EnsEMBL::Slice;
use Bio::Seq;

use EnsEMBL::Web::TextSequence::View::Alignment;

sub initialize_new {
  my ($self, $slices) = @_;
  my $hub    = $self->hub;
  my $config = {
    display_width   => $hub->param('display_width') || 60,
    species         => $self->hit->{'species'},
    maintain_colour => 1,
    comparison      => 1,
    query_seq       => 'on',
  };

  for (qw(align_display exon_display snp_display hide_long_snps line_numbering title_display)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) =~ /^(off|no)$/;
  }

  $config->{'slices'}     = $slices || $self->get_slice($config);
  $config->{'number'} = 1 if $config->{'line_numbering'};

  if (!$config->{'align_display'}) {
    splice @{$config->{'slices'}}, 1, 1;
  } elsif ($config->{'align_display'} eq 'dot') {
    $config->{'slices'}[1]{'seq'} =~ s/\|/\./g;
  }

  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'},$config);
  $self->view->markup($sequence,$markup,$config);

  return ($sequence, $config);
}

sub get_sequence_data {
  ## @override
  ## Add HSPs to the sequence data
  my ($self, $slices, $config) = @_;

  $config->{'hit'} = $self->hit;
  $config->{'job'} = $self->job;
  $config->{'object'} = $self->object;
  $config->{'slice_type'} = ref($self) =~ /QuerySeq$/ ? 'q' : 'g';
  my ($sequence, $markup) = $self->SUPER::get_sequence_data($slices, $config);

  return ($sequence, $markup);
}

sub content {
  my $self = shift;

  return '' unless $self->job;

  my ($sequence, $config) = $self->initialize_new;

  return sprintf $self->build_sequence($sequence, $config);
}

sub get_slice {
  my ($self, $config) = @_;
  my $object          = $self->object;
  my $job             = $self->job;
  my $hit             = $self->hit;
  my $blast_method    = $self->blast_method;
  my $query_seq       = $self->query_sequence($job, $hit, $blast_method);
  my $hit_seq         = $query_seq;
  my $hit_length      = $hit->{'len'};
  my $aln_summary     = $hit->{'aln'} =~ s/\s+//rg;
  my $homology_string = '|' x $hit_length;

  # take into account alignments that do not start with a match
  $aln_summary = $aln_summary =~ /^\d+/ ? $aln_summary : "0$aln_summary";

  if ($aln_summary =~ /\D/) {
    # process BTOP alignment to allow for gaps and missmatches
    $aln_summary =~ s/(\d+)/:$1:/g;
    $aln_summary =~ s/^:|:$//g;

    my @alignment_features = split ':', $aln_summary;
    my $index              = 0;

    while (scalar @alignment_features > 1) {
      my $seq_index   = shift @alignment_features;
      my $edit_string = shift @alignment_features;
      my @edits       = split '', $edit_string;

      $index += $seq_index;

      while (@edits) {
        my $query_edit = shift @edits;
        my $hit_edit   = shift @edits;
        my $length     = $query_edit eq '-' ? 0 : 1;
           $length     = $hit_edit   eq '-' ? 0 : 1 if $blast_method =~ /blastx/ && $hit->{'qori'} == -1;

        substr($query_seq,       $index, $length) = $query_edit;
        substr($hit_seq,         $index, $length) = $hit_edit;
        substr($homology_string, $index, 1)       = ' ';

        $index++;
      }
    }
  }

  # chop extra sequence strings on the right grown due to insertion of hyphens (gaps) into the original query sequence
  $query_seq  = substr $query_seq, 0, $hit_length;
  $hit_seq    = substr $hit_seq, 0, $hit_length;

  my $query_slice = $self->create_slice($hit->{'qid'}, $hit->{'qstart'}, $hit->{'qori'}, $query_seq);
  my $hit_slice   = $self->create_slice($hit->{'tid'}, $hit->{'tstart'}, $hit->{'tori'}, $hit_seq);
  my @slices;

  if ($self->is_protein) {
    @slices = (
      { name => 'Query',   slice => $query_slice,     no_markup => 1 },
      { name => '',        seq   => $homology_string, no_markup => 1 },
      { name => 'Subject', slice => $hit_slice },
    );
  } else {
    my $ref_slice     = $object->get_hit_genomic_slice($hit);
    my $target_object = $object->get_target_object($hit, $job->job_data->{'source'});
    my $orientation   = $hit->{'gori'};

    if ($target_object) {
      my $object_strand = $target_object->isa('Bio::EnsEMBL::Translation') ? $target_object->start_Exon->strand : $target_object->strand;
         $orientation   = $hit->{'tori'} eq $object_strand ? 1 : -1;
    }

    my $mapped_slice_container = $self->get_mapped_slice($hit_slice, $hit_seq, $ref_slice, $orientation);
    my $mapped_slices          = shift @{$mapped_slice_container->get_all_MappedSlices};
    my ($slice, $mapper)       = @{$mapped_slices->get_all_Slice_Mapper_pairs->[0]};

    @slices = (
      { name => 'Query',   slice => $query_slice,     no_markup => 1 },
      { name => '',        seq   => $homology_string, no_markup => 1 },
      { name => 'Subject', slice => $slice, seq => $hit_slice->seq   },
    );

    $config->{'mapper'}          = $mapper;
    $config->{'ref_slice_start'} = $ref_slice->start;
    $config->{'ref_slice_end'}   = $ref_slice->end;
  }

  return \@slices;
}

sub get_mapped_slice {
  my ($self, $hit_slice, $hit_seq, $reference_slice, $mapping_orientation) = @_;
  my $object            = $self->object;
  my $hub               = $self->hub;
  my $hit               = $self->hit;
  my $job               = $self->job;
  my $sr_name           = $reference_slice->seq_region_name;
  my $msc               = Bio::EnsEMBL::MappedSliceContainer->new(-SLICE => $reference_slice, -EXPANDED => 1);
  my $ms                = Bio::EnsEMBL::MappedSlice->new(-adaptor => $reference_slice->adaptor, -name => 'test_map', -container => $msc);
  my $mapper            = Bio::EnsEMBL::Mapper->new('mapped_slice', 'ref_slice');
  my $end               = $reference_slice->end;
  my $indel_flag        = 0;
  my $total_length_diff = 0;

  # Process genomic btop string to map coordiniates
  my $aln = $object->map_btop_to_genomic_coords($hit, $job);
     $aln =~ s/(\d+)/:$1:/g;
     $aln =~ s/^:|:$//g;

  my @alignment_features = split /:/, $aln;
  my $rev_flag           = $hit->{'gori'} ne $hit->{'tori'} ? 1 : undef;
     $rev_flag           = 1 if $hit->{'gori'} ne '1' && $hit->{'source'} =~ /latest/i;

  # Try thinking about this another way, the only bits of the btop we need to consider are
  # where we have a gap inserted into the hit sequence relative to the reference sequence
  # we know where this is due to having the hit sequence already.

  my @aln_features  = @alignment_features;
  my $seq_index     = 0;
  my $last_edit_pos = 0;
  my %edits;

  while (scalar @aln_features) {
    my $matching_bp = shift @aln_features;
    my $edit_string = shift @aln_features;
       $seq_index  += $matching_bp;

    last unless $edit_string;

    my $edit_len = length($edit_string) / 2;
    my ($type, $diffs);

    if ($edit_string =~ /^\-+$/) {
      $edits{$seq_index} = [ $seq_index - $last_edit_pos, 'gap', $edit_len ];
      $seq_index++;
      $last_edit_pos = $seq_index;
      next;
    }

    if ($edit_len > 1) {
      my @base_edits = split //, $edit_string;
      my $count      = 0;
      my $previous_state;

      while (my $query_base = $rev_flag ? pop @base_edits : shift @base_edits) {
        my $target_base = $rev_flag ? pop @base_edits : shift @base_edits;
        ($target_base, $query_base) = ($query_base, $target_base) if $rev_flag;

        my @bases = ($query_base, $target_base);
        my $state = $target_base eq '-' && $query_base  ne '-' ? 'insert_query' :
                    $query_base  eq '-' && $target_base ne '-' ? 'insert_hit'   :
                    $query_base =~ /[ACTG]/i && $target_base =~ /[ACTG]/i ? 'missmatch' : 'gap';

        if (!$previous_state) {
          $diffs->[0] = \@bases;
        } elsif ($state eq $previous_state) {
          $diffs->[$count] = [ @{$diffs->[$count]}, @bases ];
        } else {
          $count++;
          $diffs->[$count] = \@bases;
        }

        $previous_state = $state;
      }
    } else {
      my @differences = split '', $edit_string;
         $diffs->[0]  = \@differences;
    }

    my @edit_info = [ $seq_index ];

    foreach my $d (@$diffs) {
      my @differences = @{$d};
      my $length      = scalar @differences / 2;
      my $query_base  = shift @differences;
      my $target_base = shift @differences;
      my $type        = $target_base eq '-' && $query_base  ne '-' ? 'insert_query' :
                        $query_base  eq '-' && $target_base ne '-' ? 'insert_hit'   :
                        ($query_base =~ /[ACTG]/i && $target_base =~ /[ACTG]/i) ? 'missmatch' : 'gap';

      if ($type ne 'missmatch') {
        my $pos = $seq_index - $last_edit_pos;

        $edits{$seq_index} = [ $pos, $type, $length ];
        $last_edit_pos     = $seq_index;
        $last_edit_pos     = $type ne 'gap' ? $last_edit_pos += $length : $last_edit_pos + 1;
      }

      $seq_index = $type eq 'gap' ? $seq_index + 1 : $seq_index + $length;
    }
  }

  my $ref_start         = $hit->{'gstart'};
  my $ref_strand        = $hit->{'gori'};
  my $ms_start          = $rev_flag ? $hit->{'len'} : 1;
  my $total_insert_size = 0;

  foreach my $edit_position (sort { $a <=> $b } keys %edits) {
    my $num_matching_bp = $edits{$edit_position}->[0];
    my $edit_type       = $edits{$edit_position}->[1];
    my $edit_length     = $edits{$edit_position}->[2];
    my $ms_end          = $rev_flag ? $ms_start - $num_matching_bp + 1 : $ms_start + $num_matching_bp - 1;
    my $ref_end         = $ref_start + $num_matching_bp -1;

    if ($edit_type eq 'insert_hit') {
      $ms_end   = $rev_flag ? $ms_end - $edit_length : $ms_end + $edit_length;
      $ref_end += $edit_length;
    }

    ($ms_start, $ms_end) = ($ms_end, $ms_start) if $ms_start > $ms_end;

    # first add match block
    $mapper->add_map_coordinates(
      'mapped_slice',
      $ms_start,
      $ms_end,
      $mapping_orientation,
      $sr_name,
      $ref_start,
      $ref_end,
    );

    if ($edit_type eq 'insert_query') {
      $ms_start  = $rev_flag ? $ms_start - 1 - $edit_length : $ms_end + 1 + $edit_length;
      $ref_start = $ref_end + 1;
    } elsif ($edit_type eq 'insert_hit') {
      $ms_start           = $rev_flag ? $ms_start - 1 : $ms_end + 1;
      $ref_start          = $ref_end + 1;
      $total_insert_size += $edit_length;
    } else {
      $ms_start  = $rev_flag ? $ms_start - 1 : $ms_end + 1;
      $ref_start = $ref_end + $edit_length + 1;
    }
  }

#   if (($mapping_orientation == 1 && $ms_start < $seq_index) || ($mapping_orientation != 1 && $ms_start > 0)) {
#     my $ms_end = $rev_flag ? 1 : $end  - $ref_start + $ms_start;
# 
#     ($ms_start, $ms_end) = ($ms_end, $ms_start) if $ms_start > $ms_end;
# 
#     $mapper->add_map_coordinates(
#      'mapped_slice',
#       $ms_start,
#       $ms_end,
#       $mapping_orientation,,
#       $sr_name,
#       $ref_start,
#       $end,
#     );
#   }

  $reference_slice = $reference_slice->expand(undef, $total_insert_size, 1);
  $ms->add_Slice_Mapper_pair($reference_slice, $mapper);
  $msc->{'mapped_slices'} = [ $ms ];

  return $msc;
}

sub create_slice {
  my ($self, $name, $start, $strand, $seq) = @_;

  return Bio::EnsEMBL::Slice->new(
    -seq_region_name => $name,
    -start           => $start,
    -end             => $start + length($seq) - 1,
    -strand          => $strand,
    -seq             => $seq,
    -coord_system    => Bio::EnsEMBL::CoordSystem->new(
      -name => 'chromosome',
      -rank => 1,
    ),
  );
}

sub query_sequence {
  my ($self, $job, $hit, $blast_method) = @_;
  my $sequence  = $self->object->get_input_sequence_for_job($job)->{'sequence'};
  my $seq_len   = length $sequence;
  my $offset    = $hit->{'qori'} == 1 ? $hit->{'qstart'} - 1 : $seq_len - $hit->{'qstart'};

  # translate sequence if needed
  if ($blast_method =~ /blastx/i) {

    # take reverse complement if query orientation is reverse
    if ($hit->{'qori'} == -1) {
      my $map   = {qw(A T T A G C C G)};
      $sequence = join '', map { $map->{$_} } reverse split '', uc $sequence;
    }

    my $frame   = abs($hit->{'qframe'}) - 1;
    my $peptide = Bio::Seq->new(-seq => $sequence, -moltype => 'dna', -alphabet => 'dna', -id => 'sequence');
    $sequence   = $peptide->translate(undef, undef, $frame, 1)->seq;
    $offset     = ($offset - $frame) / 3;
  }

  return substr $sequence, $offset;
}

sub make_view {
  my $self = shift;
  return EnsEMBL::Web::TextSequence::View::Alignment->new(@_);
}

sub make_view {
  my ($self) = @_;

  return EnsEMBL::Web::TextSequence::View::Alignment->new($self->hub);
}

1;
