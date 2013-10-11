package EnsEMBL::Web::Component::Tools::Blast::TextSequence;

use strict;
use warnings;

use base qw(
  EnsEMBL::Web::Component::TextSequence
  EnsEMBL::Web::Component::Tools::Blast
);

sub job           { return shift->{'_job'};                       } # @return The cached requested job object
sub hit_id        { return shift->{'_hit_id'};                    } # @return ID of the result object containing the hit
sub hit           { return shift->{'_hit'};                       } # @return Result hit (hashref)
sub blast_method  { return shift->{'blast_method'};               } # @return Blast method chosen for the given job
sub is_protein    { return shift->{'is_protein'};                 } # @return Flag whether the sequence is protein or not
sub object        { return shift->SUPER::object->get_sub_object;  } ## Gets the actual blast object instead of the Tools object

sub new {
  ## @override
  ## Adds hsp_display as a key param, info about the requested job and the blast method, and adds some extra keys to the objects after instantiating it
  my $self    = shift->SUPER::new(@_);
  my $object  = $self->object;

  $self->{'_job'}           = $object->get_requested_job({'with_requsted_result' => 1}) or return $self;
  $self->{'_hit_id'}        = $self->{'_job'}->result->[0]->result_id;
  $self->{'_hit'}           = $self->{'_job'}->result->[0]->result_data;
  $self->{'_blast_method'}  = $object->parse_search_type($self->{'_job'}->job_data->{'search_type'}, 'search_method');
  $self->{'_is_protein'}    = $self->{'blast_method'} =~/^(blastx|blastp)$/i ? 1 : 0;

  push @{$self->{'key_params'}}, 'hsp_display';

  return $self;
}

sub _init {
  ## @override
  ## Sets subslice length, and makes it not-cacheable
  my $self  = shift;
  $self->SUPER::_init(5000);
  $self->cacheable(0);
};

sub get_sequence_data {
  ## @override
  ## Add HSPs to the sequence data
  my ($self, $slices, $config) = @_;
  my ($sequence, $markups) = $self->SUPER::get_sequence_data($slices, $config);

  $config->{'hsp_display'} = 'sel';

  for (my $i = 0; $i < scalar @$slices; $i++) {
    $self->set_hsps($config, $slices->[$i], $markups->[$i]) if $config->{'hsp_display'};
  }

  return ($sequence, $markups);
}

sub class_to_style {
  ## @override
  ## Add two more styles for HSPs
  my $self = shift;

  if (!$self->{'class_to_style'}) {

    $self->SUPER::class_to_style(@_); # this will set $self->{'class_to_style'}

    my $styles  = $self->hub->species_defs->colour('sequence_markup');
    my $counter = scalar keys %{$self->{'class_to_style'}};

    $self->{'class_to_style'}{'h0'} = [ ++$counter, {'font-weight' => 'bold', 'color' => "#$styles->{'SEQ_HSP0'}->{'default'}"}];
    $self->{'class_to_style'}{'h1'} = [ ++$counter, {'font-weight' => 'bold', 'color' => "#$styles->{'SEQ_HSP1'}->{'default'}"}]; #TODO - change the style to background-color to make the intersection visible
  }

  return $self->{'class_to_style'};
}

sub get_key {
  ## @override
  ## Adds the HSP key before calling the base class's method
  my ($self, $config) = @_;

  my $key = {
    'hsp' => {
      'sel'   => { 'class' => 'h0', 'text' => 'Location of selected alignment'},
      'other' => { 'class' => 'h1', 'text' => 'Location of other alignments'}
    }
  };

  return $self->SUPER::get_key($config, $key);
}

sub set_exons {
  my ($self, $config, $slice_data, $markup) = @_;
  return if $slice_data->{'no_markup'};
  my $slice    = $slice_data->{'slice'};
  my $exontype = $config->{'exon_display'};
  my ($slice_start, $slice_end, $slice_length, $slice_strand) = map $slice->$_, qw(start end length strand);
  my @exons;

  if ($exontype eq 'Ab-initio') {
    @exons = grep { $_->seq_region_start <= $slice_end && $_->seq_region_end >= $slice_start } map @{$_->get_all_Exons}, @{$slice->get_all_PredictionTranscripts};
  } elsif ($exontype eq 'vega' || $exontype eq 'est') {
    @exons = map @{$_->get_all_Exons}, @{$slice->get_all_Genes('', $exontype)};
  } else {
    @exons = map @{$_->get_all_Exons}, @{$slice->get_all_Genes};
  }
 
  # Values of parameter should not be fwd and rev - this is confusing.
  if ($config->{'exon_ori'} eq 'fwd') {
    @exons = grep { $_->strand > 0 } @exons; # Only exons in same orientation 
  } elsif ($config->{'exon_ori'} eq 'rev') {
    @exons = grep { $_->strand < 0 } @exons; # Only exons in opposite orientation
  }
 
  my @all_exons = map [ $config->{'comparison'} ? 'compara' : 'other', $_ ], @exons;

  if ($config->{'exon_features'}) {
    push @all_exons, [ 'gene', $_ ] for @{$config->{'exon_features'}};

    if ($config->{'exon_features'} && $config->{'exon_features'}->[0] && $config->{'exon_features'}->[0]->isa('Bio::EnsEMBL::Exon')) {
      $config->{'gene_exon_type'} = 'exons';
    } else {
      $config->{'gene_exon_type'} = 'features';
    }
  }
 
  foreach (@all_exons) {
    my $type = $_->[0];
    my $exon = $_->[1];

    next unless $exon->seq_region_start && $exon->seq_region_end;

    my @exon_coords;

    if ($config->{'mapper'}){
      $slice_length = $config->{'length'};
      my @temp =  $config->{'mapper'}->map_coordinates($slice->seq_region_name, $exon->seq_region_start, $exon->seq_region_end, $slice_strand, 'ref_slice');
      foreach my $mapped_coords ( @temp){
        my $start = $mapped_coords->start -1;
        my $end   = $mapped_coords->end -1; 
        my $id    = $exon->can('stable_id') ? $exon->stable_id : '';

        push @exon_coords, [$start, $end, $id];
      }
    } else {
      my $start = $exon->start - ($type eq 'gene' ? $slice_start : 1);
      my $end   = $exon->end   - ($type eq 'gene' ? $slice_start : 1);
      my $id    = $exon->can('stable_id') ? $exon->stable_id : '';
      push @exon_coords, [$start, $end, $id];
    }

      
    foreach (@exon_coords) {
      my ($start, $end, $id) = @{$_};

      ($start, $end) = ($slice_length - $end - 1, $slice_length - $start - 1) if $type eq 'gene' && $slice_strand < 0 && $exon->strand < 0;

      next if $end < 0 || $start >= $slice_length;

      $start = 0 if $start < 0;
      $end   = $slice_length - 1 if $end >= $slice_length;
      for ($start..$end) {
        push @{$markup->{'exons'}{$_}{'type'}}, $type;
        $markup->{'exons'}{$_}{'id'} .= ($markup->{'exons'}{$_}{'id'} ? "\n" : '') . $id unless $markup->{'exons'}{$_}{'id'} =~ /$id/;
      }
    }
  }
}


sub set_codons {
  my ($self, $config, $slice_data, $markup) = @_;
  return if $slice_data->{'no_markup'};

  my $slice       = $slice_data->{'slice'};
  my @transcripts = map @{$_->get_all_Transcripts}, @{$slice->get_all_Genes};
  my ($slice_start, $slice_length) = map $slice->$_, qw(start length);
  
  if ($slice->isa('Bio::EnsEMBL::Compara::AlignSlice::Slice')) {
    foreach my $t (grep { $_->coding_region_start < $slice_length && $_->coding_region_end > 0 } @transcripts) {
      next unless defined $t->translation;

      my @codons;

      # FIXME: all_end_codon_mappings sometimes returns $_ as undefined for small subslices. This eval stops the error, but the codon will still be missing.
      # Awaiting a fix from the compara team.
      eval {
        push @codons, map {{ start => $_->start, end => $_->end, label => 'START' }} @{$t->translation->all_start_codon_mappings || []}; # START codons
        push @codons, map {{ start => $_->start, end => $_->end, label => 'STOP'  }} @{$t->translation->all_end_codon_mappings   || []}; # STOP codons
      };

      my $id = $t->stable_id;
     
      foreach my $c (@codons) {
        my ($start, $end) = ($c->{'start'}, $c->{'end'});
        
        # FIXME: Temporary hack until compara team can sort this out
        $start = $start - 2 * ($slice_start - 1);
        $end   = $end   - 2 * ($slice_start - 1);

        next if $end < 1 || $start > $slice_length;

        $start = 1 unless $start > 0;
        $end   = $slice_length unless $end < $slice_length;

        $markup->{'codons'}{$_}{'label'} .= ($markup->{'codons'}{$_}{'label'} ? "\n" : '') . "$c->{'label'}($id)" for $start-1..$end-1;
      }
    } 
  } else { # Normal Slice
    foreach my $t (grep { $_->coding_region_start < $slice_length && $_->coding_region_end > 0 } @transcripts) {
      my ($start, $stop, $id, $strand) = ($t->coding_region_start, $t->coding_region_end, $t->stable_id, $slice->strand);

      if ($config->{'mapper'}){
        my @mapped_coords = $config->{'mapper'}->map_coordinates($slice->seq_region_name, $t->seq_region_start, $t->seq_region_end, $strand, 'ref_slice');

        $start = $mapped_coords[0]->start;
        $stop   = $mapped_coords[-1]->end;
      }

      # START codons
      if ($start >= 1) {
        my $label = ($strand == 1 ? 'START' : 'STOP') . "($id)";
        $markup->{'codons'}{$_}{'label'} .= ($markup->{'codons'}{$_}{'label'} ? "\n" : '') . $label for $start-1..$start+1;
      }

      # STOP codons
      if ($stop <= $slice_length) {
        my $label = ($strand == 1 ? 'STOP' : 'START') . "($id)";
        $markup->{'codons'}{$_}{'label'} .= ($markup->{'codons'}{$_}{'label'} ? "\n" : '') . $label for $stop-3..$stop-1;
      }
    }
  }
}

sub set_hsps {
  my ($self, $config, $slice_data, $markup) = @_;
  my $job           = $self->job;
  my $hub           = $self->hub;
  my $object        = $self->object;
  my $slice_type    = ref($self) =~/QuerySeq$/ ? 'q' : 'g';
  my $slice         = $slice_data->{'slice'};
  my $source_type   = $job->job_data->{'source'};
  my $slice_start   = $slice->start;
  my $slice_end     = $slice->end;
  my $slice_length  = $slice->length;
  my $hits          = [];

  if ($config->{'hsp_display'} eq 'all') {
    $hits = $slice_type eq 'g' ? $object->get_all_hits_in_slice_region($job, $slice) : $object->get_all_hits($job);
  } elsif ($config->{'hsp_display'} eq 'sel') {
    $hits = [ $self->hit_id, $self->hit ];
  }

  while (my ($hit_id, $hit) = splice @$hits, 0, 2) {

    my $is_selected_hit = $hit_id == $self->hit_id;
    my $ori             = $hub->param('orientation');
    my $g_ori           = $hit->{'gori'};
    my $invert_flag     = $ori eq 'fa' && $g_ori eq '-1' ? 1
                          : $ori eq 'fc' && $slice->strand eq '-1' ? 1
                          : $ori eq 'rc' && $slice->strand eq '-1' ? 1
                          : undef;

    if ($source_type !~/LATEST/ && $slice_type eq 'g') {
      my @coords = @{$hit->{'g_coords'}};
 
      foreach (@coords){
        my $start = $_->{'start'} - $slice_start;
        my $end = $_->{'end'} - $slice_start; 
       
        if ($invert_flag){ 
          $end = $slice_end - $_->{'start'};
          $start =  $slice_end - $_->{'end'};
        }

        $start = 0 if $start < 0;
        $end   = $slice_length - 1 if $end >= $slice_length;
        my $type = $is_selected_hit ? 'sel' : 'other';

        for ($start..$end){
          push @{$markup->{'hsps'}->{$_}{'type'}}, $type;
        }
      }
    } else { 
      my $start = $hit->{$slice_type. 'start'} - $slice_start;
      my $end = $hit->{ $slice_type. 'end'} - $slice_start;

      if ($invert_flag){  
        $start = $slice_end - $hit->{$slice_type . 'start'};
        $end =  $slice_end - $hit->{$slice_type . 'end'};
      }
      if ($start > $end ){
        my $temp = $start;
        $start = $end;  
        $end = $temp;
      }

      $start = 0 if $start < 0;
      $end   = $slice_length - 1 if $end >= $slice_length;
      my $type = $is_selected_hit ? 'sel' : 'other';

      for ($start..$end){
        push @{$markup->{'hsps'}->{$_}{'type'}}, $type;
      }
    }
  } 
}

sub markup_hsp {
  my $self = shift;
  my ($sequence, $markup, $config) = @_;
  my (%hsp_types, $hsp, $type, $seq);
  my $i = 0;

  my $class = {
    'sel' => 'h0',
    'other' => 'h1',
  };

  foreach my $data (@$markup) {
    $seq = $sequence->[$i];
    
    foreach ( sort { $a <=> $b } keys %{$data->{'hsps'}}) {
      $hsp = $data->{'hsps'}->{$_};  
      foreach $type (sort @{$hsp->{'type'}}) {
        $seq->[$_]->{'class'} = "$class->{$type} " unless $seq->[$_]->{'class'} =~ /\b$class->{$type}\b/;
        $hsp_types{$type} = 1;
      }
    }
   
    $i++;
  }

  $config->{'key'}->{'hsp'}->{$_} = 1 for keys %hsp_types
}

sub markup_blast_line_numbers {
  my ($self, $sequence, $config) = @_;
  
  # Keep track of which element of $sequence we are looking at
  my $n = 0;

  foreach my $sl (@{$config->{'slices'}}) {
    my $slice       = $sl->{'slice'};
    my $seq         = $sequence->[$n];
    my @numbering;

    if (!$slice) {
      @numbering = ({});
    } elsif ($config->{'line_numbering'} eq 'slice') {
      # Get the data for the slice
      my $ostrand     = $slice->strand;
      if (!$sl->{'no_markup'} && $config->{'transcript'}) { $ostrand =  $ostrand eq $config->{'subj_slice_strand'} ? 1 : -1; }
      my $slice_start = $sl->{'no_markup'} ? $config->{'query_slice_start'} : $config->{'ref_slice_start'};
      my $slice_end   = $sl->{'no_markup'} ? $config->{'query_slice_end'} : $config->{'ref_slice_end'};
      @numbering = ({ 
        dir   => $ostrand,
        start => $ostrand > 0 ? $slice_start : $slice_end,
        end   => $ostrand > 0 ? $slice_end   : $slice_start,
        label => $slice->seq_region_name . ':'
      });
      
    } else {
      # Line numbers are relative to the feature
      my $ostrand     = $sl->{'no_markup'} ? $config->{'query_slice_strand'} : $config->{'subj_slice_strand'};
      my $trans_start = $sl->{'no_markup'} ? $config->{'query_slice_start'} : $config->{'subj_slice_start'};
      my $trans_end   = $sl->{'no_markup'} ? $config->{'query_slice_end'} : $config->{'subj_slice_end'};

      @numbering = ({
        dir   => $ostrand,
        start => $ostrand > 0 ? $trans_start : $trans_end,
        end   => $ostrand > 0 ? $trans_end : $trans_start,
        label => ''
      });
   } 

    my $data = shift @numbering;
    my $dir = $data->{'dir'};
    my $row_start = $data->{'start'};
    my $align_end = $data->{'end'};
    my $align_length = $config->{'length'};
    my $s = 0;
    my $e = $config->{'display_width'} -1;  
    my $loop_end = $align_length + $config->{'display_width'};
    my $seq_string  = uc($sl->{'seq'} || $sl->{'slice'}->seq(1)); 
    my ($start, $end);

    while ($e < $loop_end){
      $start = '';
      $end = '';

      my $segment = substr $seq_string, $s, $config->{'display_width'};
      (my $seq_length_seg = $segment) =~ s/\-//g;
      my $seq_length      = length $seq_length_seg;

      if ( !$sl->{'no_markup'} && $config->{'line_numbering'} eq 'slice' ){ # we have the mapped slice

        my $first_bp_pos    = 1; # Position of first letter character
        my $last_bp_pos     = 0; # Position of last letter character

        if ($segment =~ /\w/) {
          $segment      =~ /(^\W*).*\b(\W*$)/;
          $first_bp_pos = 1 + length $1 unless length($1) == length $segment;
          $last_bp_pos  = $2 ? length($segment) - length($2) : length $segment;
        }
        my $cs = $s + $first_bp_pos; 
        my $ce = $s + $last_bp_pos;

        my @mapped_coords = ( sort { $a->start <=> $b->start }
                              grep { ! $_->isa('Bio::EnsEMBL::Mapper::Gap') }
                              $config->{'mapper'}->map_coordinates('mapped_slice', $cs, $ce, $dir, 'mapped_slice')
                            );

        $start =  $mapped_coords[0]->start;
        $end =  $mapped_coords[-1]->end;  
        ($start, $end) = ($end, $start) if $dir ne '1';

      } else {
        if ($dir eq '1'){
          $start = $row_start;
          $end = $row_start + $seq_length -2 > $align_end ? $align_end : $row_start + $seq_length -1;  
          $row_start = $end +1;  
        }else {
          $start = $row_start;
          $end = $row_start - $seq_length + 1;
          $row_start = $end -1; 
        } 
      } 

      push @{$config->{'line_numbers'}{$n}}, { start => $start, end => $end} unless $sl->{'no_numbers'};
      $config->{'padding'}{'number'} = length $start if length $start > $config->{'padding'}{'number'};

      $s = $e + 1;
      $e += $config->{'display_width'};
    }
    $n++;
  }
}

sub content_key {
  my $self   = shift;
  my $config = shift || {};
  my $hub    = $self->hub;

  $config->{'site_type'} = ucfirst(lc $hub->species_defs->ENSEMBL_SITETYPE) || 'Ensembl';

  for (@{$self->{'key_params'}}, qw(exon_display population_filter min_frequency consequence_filter)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off';
  }

  $config->{'key'}->{$_} = $hub->param($_) for @{$self->{'key_types'}};

  for my $p (grep $hub->param($_), qw(exons variations)) {
    $config->{'key'}->{$p}->{$_} = 1 for $hub->param($p);
  }

  return $self->get_key($config);
}

1;
