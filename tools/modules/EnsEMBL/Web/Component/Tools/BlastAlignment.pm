package EnsEMBL::Web::Component::Tools::BlastAlignment;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Tools);

use Bio::EnsEMBL::Slice;
use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::MappedSliceContainer;
use Bio::EnsEMBL::MappedSlice;
use Bio::EnsEMBL::Mapper;
use Bio::Seq;

sub _init {
  my $self = shift;
  my $hub = $self->hub;
  
  $self->cacheable(0);
  $self->ajaxable(1);
  
  $self->{'subslice_length'} = $hub->param('force') || 5000 * ($hub->param('display_width') || 60)
};

sub initialize {
  my ($self, $slice, $start, $end) = @_;
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $hub = $self->hub;
  my $species_defs = $hub->species_defs;
  my $ticket = $object->ticket;
  my $ticket_id = $ticket->ticket_id;
  my $hit_id = $hub->param('hit');
  my $result_id = $hub->param('res');
  my $species = $object->get_hit_species($result_id);
  my $genomic_hit = $object->fetch_blast_hit_by_id($result_id);
  my $blast_method = $object->get_blast_method;
  my $protein = $blast_method =~/[blastx]|[blastp]/i ? 1 : undef;

  my $html;

  my $config = {
    display_width   => $hub->param('display_width') || 60,
    species         => $species,
    comparison      => 1,
    blast_alignment => 1,
  };


  foreach ('exon_ori', 'match_display', 'snp_display', 'line_numbering', 'codons_display', 'title_display', 'exon_display'){
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off' || $hub->param($_) eq 'no';
  }

  $config->{'end_number'}      = $config->{'number'} = 1 if $config->{'line_numbering'};
  $config->{'exon_display'}    = 'selected' if $config->{'exon_ori'};
  $config->{'query_seq'}       = 'on';

  $config->{'slices'} = $self->get_alignment_slices($genomic_hit, $species, $config);

  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);
  $self->markup_codons($sequence, $markup, $config)         if $config->{'codons_display'};
  $self->markup_exons($sequence, $markup, $config)          if $config->{'exon_display'};
  $self->markup_variation($sequence, $markup, $config)      if $config->{'snp_display'};
  $self->markup_comparisons($sequence, $markup, $config); # Always called in this view
  $self->markup_blast_line_numbers($sequence, $config)      if $config->{'line_numbering'};

  $html  .= sprintf('<div class="sequence_key">%s</div>', $self->get_key($config));
  $html .= $self->build_sequence($sequence, $config);
  return $html;
}

sub get_alignment_slices {
  my ($self, $hit, $species, $config) = @_;
  my $object = $self->object;
  my $result_id = $self->hub->param('res');
  my $homology_string;
  my $blast_method = $object->get_blast_method;
  my $protein = $blast_method =~/(blastx)|(blastp)/i ? 1 : undef;

  my $query_seq = $self->query_sequence($hit, $blast_method);
  my $hit_seq   = $query_seq;
  my $aln_summary = $hit->{'aln'};
  $aln_summary =~s/\s+//g;
  $homology_string = "|" x $hit->{'len'};

  # take into account alignments that do not start with a match
  $aln_summary = $aln_summary =~/^\d+/ ? $aln_summary : '0' .$aln_summary;

  if ($aln_summary =~/\D/){
    # process BTOP alignment to allow for gaps and missmatches
    $aln_summary =~ s/(\d+)/:$1:/g;
    $aln_summary =~ s/^:|:$//g;
    my @alignment_features = split (/:/, $aln_summary);
    my $index = 0;

    while ( scalar @alignment_features > 1){  
      my $seq_index = shift @alignment_features;  
      $index += $seq_index;
      my $edit_string = shift @alignment_features;
      my @edits = split (//, $edit_string);

      while (@edits){
        my $query_edit = shift @edits;
        my $hit_edit = shift @edits;
      
        my $length = $query_edit eq '-' ? 0 : 1;
        substr($query_seq, $index, $length) = $query_edit;
        substr($hit_seq, $index, $length) = $hit_edit;
        substr($homology_string, $index, 1) = ' ';
        $index++;
      }
    }
  }

 
  my $ref_slice = $object->get_hit_genomic_slice($hit, $species);
  my $target_object = $object->get_target_object($hit);
  my $mapping_orientation = $hit->{'gori'};
  if ($target_object){
    my $object_strand = $target_object->isa('Bio::EnsEMBL::Translation') ? $target_object->translation->start_Exon->strand :
                        $target_object->strand;
    $mapping_orientation = $hit->{'tori'} eq $object_strand ? 1 : -1; 
  }
 
  my $spacer = " " x (length($homology_string));

  my $query_slice = $self->create_slice($hit->{'qid'}, $hit->{'qstart'}, $hit->{'qori'}, $query_seq, $ref_slice);
  my $hit_slice   = $self->create_slice($hit->{'tid'}, $hit->{'tstart'}, $hit->{'tori'}, $hit_seq, $ref_slice);
  my @slices;

  if ($protein){
    @slices = (
      { name => 'Query', slice => $query_slice, no_markup => 1},
      { name => '', slice => $query_slice, seq => $homology_string, no_markup => 1, no_numbers => 1},
      { name => 'Subjct', slice => $hit_slice, },
    );
  } else {
    my $mapped_slice_container = $self->get_mapped_slice($hit_slice, $hit_seq, $ref_slice, $mapping_orientation);

    my $ms =  shift @{$mapped_slice_container->get_all_MappedSlices};
    my $slice =  $ms->get_all_Slice_Mapper_pairs->[0][0];

    @slices = (
      { name => 'Query', slice => $query_slice, no_markup => 1 },    
      { name => '', slice => $query_slice, seq => $homology_string, no_markup => 1, no_numbers => 1},
      { name => 'Subjct', slice => $slice, seq => $hit_slice->seq, msc => $mapped_slice_container },
    ); 
 
    my $mapper = $ms->get_all_Slice_Mapper_pairs->[0][1];
    $config->{'mapper'} = $mapper;
    $config->{'ref_slice_start'}  = $ref_slice->start;
    $config->{'ref_slice_end'}    = $ref_slice->end; #length ($ms->seq);
    $config->{'ref_slice_name'}   = ' '; 
    $config->{'query_slice_start'} = $hit->{'qstart'};
    $config->{'query_slice_end'}  = $hit->{'qend'}; 
    $config->{'query_slice_strand'} = $hit->{'qori'};
    $config->{'subj_slice_start'} = $hit->{'tstart'};
    $config->{'subj_slice_end'}  = $hit->{'tend'};
    $config->{'subj_slice_strand'}  = $hit->{'tori'};
    $config->{'transcript'} = 1 if $self->hub->action =~/transcript/i;
  } 

  return \@slices;
}

sub get_mapped_slice {
  my ($self, $hit_slice, $hit_seq, $reference_slice, $mapping_orientation) = @_;
  my $object = $self->object; 
  my $hub = $self->hub;
  my $result_id = $hub->param('res'); 
  my $hit = $object->fetch_blast_hit_by_id($result_id);  
  my $species = $object->get_hit_species($result_id);

  my $sr_name = $reference_slice->seq_region_name;
  my $msc = Bio::EnsEMBL::MappedSliceContainer->new( -SLICE => $reference_slice, -EXPANDED => 1);
  my $ms = Bio::EnsEMBL::MappedSlice->new( -adaptor => $reference_slice->adaptor, -name => 'test_map', -container => $msc);
  my $mapper = Bio::EnsEMBL::Mapper->new('mapped_slice', 'ref_slice');  
  my $end = $reference_slice->end; 
  my $indel_flag = 0;
  my $total_length_diff = 0;

  # Process genomic btop string to map coordiniates
  my $aln = $hit->{'db_type'} =~/cdna/i ?  $object->map_btop_to_genomic_coords($hit, $result_id) : $hit->{'aln'};
  if ($hit->{'gori'} ne '1' && $hit->{'db_type'}=~/latest/i){
    $aln = $object->reverse_btop($aln);
  }

  $aln =~ s/(\d+)/:$1:/g;
  $aln  =~ s/^:|:$//g;

  my @alignment_features = split (/:/, $aln);
  my $rev_flag = $hit->{'gori'} ne $hit->{'tori'} ? 1 : undef;
  if ($hit->{'gori'} ne '1' && $hit->{'db_type'}=~/latest/i){
    $rev_flag = 1;
  }

  # Try thinking about this another way, the only bits of the btop we need to consider are
  # where we have a gap inserted into the hit sequence relative to the reference sequence
  # we know where this is due to having the hit sequence already.

  my @aln_features = @alignment_features;

  my %edits;
  my $seq_index = 0;
  my $last_edit_pos = 0;
  
  while (scalar @aln_features){
    my $matching_bp = shift @aln_features;
    my $edit_string = shift @aln_features;
    $seq_index += $matching_bp; 
    last unless $edit_string;
    my $edit_len = length($edit_string)/2;
    my $type;
    my $diffs;


    if ($edit_len > 1){
      my @base_edits = split(//, $edit_string);
      my $previous_state;
      my $count = 0;
      while (my $query_base = !$rev_flag ? shift @base_edits : pop @base_edits){
        my $target_base = !$rev_flag ? shift @base_edits : pop @base_edits;
        ($target_base, $query_base) = ($query_base, $target_base) if $rev_flag;
        my $state = $target_base eq '-' && $query_base ne '-' ? 'insert_query' :
                    $query_base eq '-' && $target_base ne '-' ?'insert_hit' :
                    ($query_base =~/[ACTG]/i && $target_base =~/[ACTG]/i) ? 'missmatch' : 'gap';

        my @bases = ($query_base, $target_base);
        if (!$previous_state){
          $diffs->[0] = \@bases;
        } elsif ( $state eq $previous_state){
          my @temp = @{$diffs->[$count]};
          push @temp,  @bases;
          $diffs->[$count] = \@temp;
        } else {
          $count++;
          $diffs->[$count] = \@bases;
        };
        $previous_state = $state;
      } 
    } else {
      my @differences = split(//, $edit_string);
      $diffs->[0] = \@differences;
    }

    my @edit_info = [$seq_index];

    foreach my $d (@{$diffs}){
      my @differences = @{$d};
      my $length = (scalar @differences)/2;
      my $query_base = shift @differences; 
      my $target_base = shift @differences;

      my $type = $target_base eq '-' ? 'insert_query' : 
                  $query_base eq '-' && $target_base ne 'N' ?'insert_hit' :
                  ($query_base =~/[ACTG]/i && $target_base =~/[ACTG]/i) ? 'missmatch' : 'gap';

      if ($type ne 'missmatch'){
        my $pos = $seq_index - $last_edit_pos; 
        $edits{$seq_index} = [$pos, $type, $length];
        $last_edit_pos = $seq_index;
        $last_edit_pos = $type ne 'gap' ? $last_edit_pos += $length : $last_edit_pos +1; 
      }
      $seq_index = $type eq 'gap' ? $seq_index +1 : $seq_index + $length;
    }
  }

  my $ref_start = $hit->{'gstart'};
  my $ref_strand = $hit->{'gori'};
  my $ms_start = !$rev_flag ? 1 : $hit->{'len'};
  my $total_insert_size = 0;

  
  foreach my $edit_position (sort {$a <=> $b } keys %edits){

    my $num_matching_bp = $edits{$edit_position}->[0];     
    my $edit_type  =  $edits{$edit_position}->[1];
    my $edit_length =  $edits{$edit_position}->[2];
    my $ms_end = !$rev_flag ? ($ms_start + $num_matching_bp) -1 : ($ms_start - $num_matching_bp) +1;
    my $ref_end = ($ref_start + $num_matching_bp) -1;
#warn "$num_matching_bp $edit_type";
    if ($edit_type eq 'insert_hit'){ 
      $ms_end = !$rev_flag ? $ms_end + $edit_length : $ms_end - $edit_length; 
      $ref_end += $edit_length; 
    }

    ($ms_start, $ms_end) = ($ms_end, $ms_start) if $ms_start > $ms_end;

#warn "$ms_start $ms_end $ref_start $ref_end";

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

    if ($edit_type eq 'insert_query'){
      $ms_start = !$rev_flag ? $ms_end + 1 + $edit_length : $ms_start -1 - $edit_length;
      $ref_start = $ref_end +1;
    } elsif ($edit_type eq 'insert_hit'){
      $ms_start = !$rev_flag ? $ms_end +1 : $ms_start -1;
      $ref_start = $ref_end + 1;
      $total_insert_size += $edit_length;  
    } else {
      $ms_start = !$rev_flag ? $ms_end +1 : $ms_start -1;
      $ref_start = $ref_end + $edit_length +1;
    }
  }   

  if ( ($mapping_orientation == 1 && $ms_start < $seq_index) || ($mapping_orientation != 1 && $ms_start > 0)){
    my $ms_end = !$rev_flag ? ($end  - $ref_start ) + $ms_start : 1;
    ($ms_start, $ms_end) = ($ms_end, $ms_start) if $ms_start > $ms_end;
#warn "$ms_start $ms_end $ref_start $end";
    $mapper->add_map_coordinates(
     'mapped_slice',
      $ms_start,
      $ms_end,
      $mapping_orientation,,
      $sr_name,
      $ref_start,
      $end,
    );
  }

  $reference_slice = $reference_slice->expand(undef, $total_insert_size, 1);
  $ms->add_Slice_Mapper_pair($reference_slice, $mapper);
  $msc->{'mapped_slices'} = [$ms];

  return $msc;
}

sub create_slice {
  my ($self, $name, $start, $strand, $seq, $ref_slice) = @_;
  my $object = $self->object;
  
  my $length = length($seq);
  
  my $coord_system   = Bio::EnsEMBL::CoordSystem->new(
    -name     => 'chromosome',
    -version  => undef,
    -rank     => 1
  );


  my $slice = Bio::EnsEMBL::Slice->new(
    -coord_system     => $coord_system,
    -seq_region_name  => $name,
    -start            => $start,
    -end              => $start + $length -1,
    -strand           => $strand,
    -seq              => $seq,
  );

  return $slice;
}

sub query_sequence {
  my ($self, $hit, $blast_method) = @_;
  my $object = $self->object;
  my $query_sequence = $object->complete_query_sequence($hit);
  my $start = $hit->{'qstart'};
  my $end = $hit->{'qend'};
  my $length = $end - $start +1;

 
  if ($blast_method =~/blastx/i){
    my $codon_table_id ||= 1;
    my $frame  = $hit->{'qframe'};
    $length = $length /3;

    if ($frame =~/\-/){
      $query_sequence = reverse($query_sequence);
      $query_sequence =~tr/ACGTacgt/TGCAtgca/;
      $frame =~s/\-//;
    }
  
    $frame = $frame > 0 ? $frame -=1 : $frame;

    my $peptide = Bio::Seq->new( -seq       => $query_sequence,
                                 -moltype   => 'dna', 
                                 -alphabet  => 'dna',
                                 -id        => 'sequence' );

    my $translation = $peptide->translate ( undef, undef, $frame, 
                                         $codon_table_id, undef,
                                         undef, undef );

    $query_sequence = $translation->seq;
    $query_sequence =~s/\*$//;

    if ($hit->{'qori'} =~/\-/){
      my $trans_length = length($query_sequence);
      $start = $trans_length - ($hit->{'qstart'} /3) +1;    
    } else {
      $start = ($hit->{'qstart'} /3) +1;
    }
      
  }

  my $offset = $start -1;
  my $seq = substr($query_sequence, $offset, $length);

  return $seq;
}
 
1;
