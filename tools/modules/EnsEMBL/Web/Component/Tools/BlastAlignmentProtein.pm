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
  my $database_type = $hit->{'db_type'};
  my $translation_id = $hit->{'tid'};
  $config->{'length'} = $hit->{'len'}; 
  $config->{'Subjct_start'} = $hit->{'tstart'};
  $config->{'Subjct_end'}   = $hit->{'tend'};
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
  my $flip = 1;  
  my $offset = $config->{'Subjct_start'} -1;
  my @exon_len = sort {$a <=> $b} keys %$exons;
  my $index = 0;
  my @seq = split(//, $seq);
  my $count;

  while ( my $exon_length = shift @exon_len){    
    if ( $index + $exon_length < $offset -1){      
        $index += $exon_length;
        next;
    }  
    $flip = 1 - $flip if $exons->{$exon_length}->{'exon'};  
    $count = 0;
    while ( $count < $exon_length ){ 
      if ($index >= $offset){
        my $base = $seq[$index];
        if ( $base ne '-'){
          my $style = "exon$flip";
          if ($exons->{$index}->{'overlap'}) {
            $style = 'exon2';
            my $temp = shift @exon_len;
          }   
          push @{$markup->{'exons'}->{$index}->{'type'}}, $style;
          $count++;
        }
      } 
      $index++;
      last if $index >= $config->{'length'};    
    }
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
  
  while ($seq_index <= $config->{'Subjct_end'}){
    my $base = $seq[$seq_pos];
    if ($base ne '-') {
      $position->{$actual_pos} = $seq_pos;
      $actual_pos++;
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
    my $loop_end = $config->{'length'} + $config->{'display_width'}; 
    my $seq_offset = 0;

    while ($e < $loop_end){
      $e = $e + $config->{'display_width'} > $data->{'end'} ? $data->{'end'} : $e += $config->{'display_width'};       
      my $shift = 0; # To check if we've got a new element from @numbering
      my $length = $e == $data->{'end'} ? ($e -$s) +1: $config->{'display_width'};

      my $sequence = $sl->{'seq'} || $slice->seq;
      my $segment = substr $sequence, $seq_offset, $length;
      my $seg_length = length $segment;
      my @bases = split(//, $segment);
      my $gap_count = grep(/-/, @bases);
      my $label = '';

      $e -= $gap_count;     
      push @{$config->{'line_numbers'}{$n}}, { start => $s, end => $e, label => $label };
      $s = $e +1;
      $seq_offset += $config->{'display_width'};
    }
    $n++;
  }
}

1;
