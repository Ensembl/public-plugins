package EnsEMBL::Web::Component::Tools::Blast::AlignmentProtein;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools::Blast::Alignment);

sub get_sequence_data {
  my ($self, $slices, $config) = @_;
  my $hub           = $self->hub;
  my $object        = $self->object;
  my $job           = $self->job;
  my $job_data      = $job->job_data;
  my $species       = $job_data->{'species'};
  my $hit           = $self->hit;
  my $blast_method  = $self->blast_method;
  my $source_type   = $job_data->{'source'};
  my $adaptor       = $hub->get_adaptor(sprintf('get_%sAdaptor', $source_type =~ /abinitio/i ? 'PredictionTranscript' :'Translation'), 'core', $species);

  $config->{'length'}         = $hit->{'len'}; 
  $config->{'Subject_start'}  = $hit->{'tstart'};
  $config->{'Subject_end'}    = $hit->{'tend'};
  $config->{'Subject_ori'}    = $hit->{'tori'};  
  $config->{'Query_start'}    = $hit->{'qstart'};
  $config->{'Query_end'}      = $hit->{'qend'};

  if ($blast_method eq 'TBLASTN') {
    $config->{'Subject_start'} = $hit->{'gori'} == 1  ? $hit->{'gstart'} : $hit->{'gend'};
    $config->{'Subject_end'}   = $hit->{'gori'} == 1  ? $hit->{'gend'}   : $hit->{'gstart'};
    $config->{'Subject_ori'}   = $hit->{'gori'};
  }

  my $transcript_web_object;

  if ($source_type !~/latestgp/i) { # Can't markup based on protein sequence as we only have a translated DNA region
    my $transcript          = $adaptor->fetch_by_stable_id($hit->{'tid'});
       $transcript          = $transcript->transcript unless $transcript->isa('Bio::EnsEMBL::Transcript');
    $transcript_web_object  = $self->new_object( 'Transcript', $transcript, $self->object->__data );
  }

  my $sequence = [];
  my @markup;

  foreach my $slice (@$slices) {
    my $seq = uc($slice->{'seq'} || $slice->{'slice'}->seq(1));
    my $mk  = {};
    $self->set_sequence($config, $sequence, $mk, $seq, $slice->{'name'});
    unless ($slice->{'no_markup'} || $source_type =~/latestgp/i ) {
      $self->set_exons($config, $slice, $mk, $transcript_web_object, $seq)      if $config->{'exon_display'};
      $self->set_variations($config, $slice, $mk, $transcript_web_object, $seq) if $config->{'snp_display'};
    }
    push @markup, $mk;
  }

  return ($sequence, \@markup);
}

sub set_exons {
  my ($self, $config, $sl, $markup, $transcript, $seq)= @_;

  my $exons = $transcript->peptide_splice_sites;
  my @sequence = split //, $seq;
  my $temp_flip = 1;  
  my $flip = 0;
  my $offset = $config->{'Subject_start'} -1;
  my %exon_feats_to_markup;
  my $seq_index = 0;
  my $actual_index = 0;  
  my $style;

  foreach (sort {$a <=> $b} keys %$exons){
    $temp_flip = 1 - $temp_flip;
    my $offset_position = $_ - $offset;
    
    if ($offset_position < 0) {
      $flip = 1 - $temp_flip;
      next;
    }
    last if $offset_position > $config->{'Subject_end'};

    $exon_feats_to_markup{$offset_position} = exists $exons->{$_}->{'overlap'} ? 'overlap' : 'exon';
  }

  my @markup_positions = sort {$a <=> $b} keys %exon_feats_to_markup;
  my $next_markup_pos  = shift @markup_positions;


  while ($actual_index < $config->{'length'}){
    my $base = $sequence[$actual_index];

    if ($base ne '-'){
      if ($seq_index == $next_markup_pos) { 
        my $markup_type = $exon_feats_to_markup{$seq_index}; 
        $flip = 1 - $flip  if $markup_type eq 'exon';
        $style = $markup_type eq 'overlap' ? 'exon2' : "exon$flip";
        $next_markup_pos = shift @markup_positions || undef;
      } else {
        $style = "exon$flip";
      }
      push @{$markup->{'exons'}->{$actual_index}->{'type'}}, $style;        
      $seq_index++;
    }  
    $actual_index++;
  }
}

sub set_variations {
  my ($self, $config, $sl, $markup, $transcript, $seq)= @_;
  my $translation = $transcript->translation_object;
  my $strand   = $transcript->Obj->strand;
  my $seq_index = $config->{'Subject_start'};
  my $actual_pos = $seq_index;
  my $seq_pos = 0;
  my $position;
  my @seq = split (//, $seq);
  my $end = $config->{'Subject_end'}; 
 
  while ($seq_index <= $end){
    my $base = $seq[$seq_pos];
    if ($base ne '-') {
      $position->{$actual_pos} = $seq_pos;
      $actual_pos++;
    } else {
      $end++;
    }
    $seq_pos++;
    $seq_index++;
  }

  foreach my $snp (reverse @{$transcript->variation_data($translation->get_Slice, undef, $strand)}) {
    my $temp_pos  = $snp->{'position'};
    next if $temp_pos < $config->{'Subject_start'} || $temp_pos > $config->{'Subject_end'};
    my $pos = $position->{$temp_pos};
    my $dbID = $snp->{'vdbid'};

    $markup->{'variations'}->{$pos}->{'type'}    = lc($config->{'consequence_filter'} ? [ grep $config->{'consequence_filter'}{$_}, @{$snp->{'tv'}->consequence_type} ]->[0] : $snp->{'type'});
    $markup->{'variations'}->{$pos}->{'alleles'} = $snp->{'allele'};
    $markup->{'variations'}->{$pos}->{'href'} ||= {
      type        => 'ZMenu',
      action      => 'TextSequence',
      factorytype => 'Location'
    };

    push @{$markup->{'variations'}->{$pos}->{'href'}->{'v'}},  $snp->{'snp_id'};
    push @{$markup->{'variations'}->{$pos}->{'href'}->{'vf'}}, $dbID;
  }
}

sub markup_blast_line_numbers {
  my ($self, $sequence, $config) = @_;
  my $blast_method = $self->blast_method;

  # Keep track of which element of $sequence we are looking at
  my $n = 0;

  foreach my $sl (@{$config->{'slices'}}) {
    if ($sl->{'no_numbers'}) {
      $n++;
      next;
    }

    my $slice       = $sl->{'slice'};
    my $name        = $sl->{'name'};
    my $seq         = $sequence->[$n];
    my $rev;
    if($name eq 'Subject') {
      $rev = $config->{'Subject_ori'} == 1 ? undef : 1;
    }

    my @numbering;

    if (!$slice) {
      @numbering = ({});
    } else {
       @numbering = ({
        dir   => 1,
        start => $config->{$name .'_start'},
        end   => $config->{$name .'_end'},
        label => ''
      });
    }
  
    my $data = shift @numbering;
    my $s = !$rev ? $data->{'start'} : $data->{'end'};
    my $e = $s -1;
    my $loop_end = !$rev ? $data->{'end'} : $data->{'start'};
    my $start = $data->{'start'};
    my $seq_offset = 0;

    my $multiplication = ($blast_method eq 'TBLASTN' && $name eq 'Subject') || ($blast_method eq 'BLASTX' && $name eq 'Query') ? 3 : 1;

    while ($s < $loop_end){

      if ($e + ($config->{'display_width'} * $multiplication )  > $loop_end){ $e = $loop_end; }
      else { $e += ( $config->{'display_width'}  * $multiplication) ; }
      my $length = $e >= $loop_end ? ($e -$s) +1 : $config->{'display_width'};

      my $sequence = $sl->{'seq'} || $slice->seq;
      my $segment = substr $sequence, $seq_offset, $length;

      my $seg_length = length $segment;
      my @bases = split(//, $segment);
      my $gap_count = grep(/-/, @bases);
      my $label = '';
      my $num_matches = $seg_length - $gap_count;
    
      $num_matches = $num_matches * $multiplication;

      my $end;
      if ($rev){
        $end = $start - $num_matches + 1;
        $end = $data->{'end'} if $end < $data->{'end'};
      } else { 
        $end  =  $e >= $data->{'end'} ? $data->{'end'} : $start + $num_matches -1;
        $end = $data->{'end'} if $end > $data->{'end'};
      }

      push @{$config->{'line_numbers'}{$n}}, { start => $start, end => $end, label => $label };
      $config->{'padding'}{'number'} = length $s if length $s > $config->{'padding'}{'number'};
 
      $e = !$rev ? $e - $gap_count : $e + $gap_count;
      $s = $e +1;
      $start = !$rev ? $end+1 : $end -1;  
      $seq_offset += $config->{'display_width'};
    }

    $n++;
  }
}

1;
