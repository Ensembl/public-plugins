package EnsEMBL::Web::Component::Tools::BlastAlignmentProtein;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Tools::BlastAlignment);

sub get_sequence_data {
  my ($self, $slices, $config) = @_;
  my $hub = $self->hub;
  my $object = $self->object;
  my $result_id = $self->hub->param('res');
  my $species = $object->get_hit_species($result_id);  
  my $hit = $object->fetch_blast_hit_by_id($result_id);
  my $method = lc ($hub->param('method'));
  my $database_type = $hit->{'db_type'};
  my $translation_id = $hit->{'tid'};
  $config->{'length'} = $hit->{'len'}; 
  $config->{'Subjct_start'} = $method eq 'tblastn' ? $hit->{'gstart'} : $hit->{'tstart'};
  $config->{'Subjct_end'}   = $method eq 'tblastn' ? $hit->{'gend'} : $hit->{'tend'};
  $config->{'Query_start'} = $hit->{'qstart'};
  $config->{'Query_end'}   = $hit->{'qend'};


  my $feature_type = $database_type =~ /abinitio/i ? 'PredictionTranscript' :'Translation';

  my $adaptor = $hub->get_adaptor('get_' . $feature_type .'Adaptor', 'core', $species);

  my ($translation, $transcript);  

  if ($database_type !~/latestgp/i){ # Can't markup based on protein sequence as we only have a translated DNA region 
    $translation = $adaptor->fetch_by_stable_id($hit->{'tid'}); 
    my $temp_trans = $translation->transcript;
  
    $transcript = $self->new_object(
      'Transcript', $temp_trans, $self->object->__data
    );
  }

  my $sequence = [];
  my @markup;

  foreach my $sl (@$slices){
    my $seq = uc($sl->{'seq'} || $sl->{'slice'}->seq(1));
    my $mk = {};
    $self->set_sequence($config, $sequence, $mk, $seq, $sl->{'name'});
    unless ($sl->{'no_markup'} || $database_type =~/latestgp/i ){ 
      $self->set_exons($config, $sl, $mk, $transcript, $seq) if $config->{'exon_display'};
      $self->set_variations($config, $sl, $mk, $transcript, $seq) if $config->{'snp_display'};
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
  my $offset = $config->{'Subjct_start'} -1;
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
    last if $offset_position > $config->{'Subjct_end'};

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
  my $seq_index = $config->{'Subjct_start'};
  my $actual_pos = $seq_index;
  my $seq_pos = 0;
  my $position;
  my @seq = split (//, $seq);
  my $end = $config->{'Subjct_end'}; 
 
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
    next if $temp_pos < $config->{'Subjct_start'} || $temp_pos > $config->{'Subjct_end'};
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
  my $method = $self->hub->param('method');

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
    my $s = $data->{'start'};
    my $e = $s -1;
    my $loop_end = $data->{'end'};
    my $seq_offset = 0;

    while ($s < $loop_end){
      if ($e + $config->{'display_width'} > $data->{'end'}){ $e = $data->{'end'}; }
      else { $e += $config->{'display_width'}; }

      my $length = $e >= $data->{'end'} ? ($e -$s) +1 : $config->{'display_width'};

      my $sequence = $sl->{'seq'} || $slice->seq;
      my $segment = substr $sequence, $seq_offset, $length;

      my $seg_length = length $segment;
      my @bases = split(//, $segment);
      my $gap_count = grep(/-/, @bases);
      my $label = '';
      my $num_matches = $seg_length - $gap_count;
    
      $num_matches = $num_matches * 3 if $method eq 'tblastn' && $name eq 'Subjct';
      my $end = $s + $num_matches -1;

      $end = $data->{'end'} if $end > $data->{'end'};

      push @{$config->{'line_numbers'}{$n}}, { start => $s, end => $end, label => $label };
      $config->{'padding'}{'number'} = length $s if length $s > $config->{'padding'}{'number'};
      $s = $end +1;
      $e = $end;
      $seq_offset += $config->{'display_width'};
    }
    $n++;
  }
}

1;
