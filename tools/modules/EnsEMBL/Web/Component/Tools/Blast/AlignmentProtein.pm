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

package EnsEMBL::Web::Component::Tools::Blast::AlignmentProtein;

use strict;

use parent qw(EnsEMBL::Web::Component::Tools::Blast::Alignment);

use EnsEMBL::Web::TextSequence::View::AlignmentProtein;

sub get_sequence_data {
  my ($self, $slices, $config) = @_;
  my $job         = $self->job;
  my $hit         = $self->hit;
  my $source_type = $job->job_data->{'source'};
  my (@markup, $object);
  
  $config->{'length'}        = $hit->{'len'}; 
  $config->{'Subject_start'} = $hit->{'tstart'};
  $config->{'Subject_end'}   = $hit->{'tend'};
  $config->{'Subject_ori'}   = $hit->{'tori'}; 
  $config->{'Query_start'}   = $hit->{'qstart'};
  $config->{'Query_end'}     = $hit->{'qend'};

  $config->{'source_type'} = $source_type;
  
  if ($self->blast_method eq 'TBLASTN') {
    $config->{'Subject_start'} = $hit->{'gori'} == 1 ? $hit->{'gstart'} : $hit->{'gend'};
    $config->{'Subject_end'}   = $hit->{'gori'} == 1 ? $hit->{'gend'}   : $hit->{'gstart'};
    $config->{'Subject_ori'}   = $hit->{'gori'};
  }
 
  $config->{'blast_method'} = $self->blast_method; 
  $config->{'transcript'} = undef;

  if ($source_type !~ /latestgp/i) { # Can't markup based on protein sequence as we only have a translated DNA region
    my $adaptor    = $self->hub->get_adaptor(sprintf('get_%sAdaptor', $source_type =~ /abinitio/i ? 'PredictionTranscript' : 'Translation'), 'core', $job->species);
    my $transcript = $adaptor->fetch_by_stable_id($hit->{'tid'});
     $transcript = $transcript->transcript unless $transcript->isa('Bio::EnsEMBL::Transcript');
     $object     = $self->new_object('Transcript', $transcript, $self->object->__data);
    $_->{'transcript'} = $object for(@$slices);
  }
  
  my $view = $self->view;
  $view->set_annotations($config);
  $view->prepare_ropes($config,$slices);
  my @sequences = @{$view->sequences};
  foreach my $slice (@$slices) {
    my $sequence = shift @sequences;
    my $seq = uc($slice->{'seq'} || $slice->{'slice'}->seq(1));
    my $mk  = {};
 
    $view->annotate($config,$slice,$mk,$seq,$sequence);
    push @markup, $mk;
  }

  return ([@{$view->sequences}], \@markup);
}

sub set_exons {
  my ($self, $config, $sl, $markup, $transcript, $seq) = @_;
  my $exons        = $transcript->peptide_splice_sites;
  my @sequence     = split '', $seq;
  my $offset       = $config->{'Subject_start'} - 1;
  my $temp_flip    = 1;
  my $flip         = 0;
  my $seq_index    = 0;
  my $actual_index = 0;
  my (%exon_feats_to_markup, $style);

  foreach (sort { $a <=> $b } keys %$exons) {
    my $offset_position = $_ - $offset;
       $temp_flip       = 1 - $temp_flip;
    
    if ($offset_position < 0) {
      $flip = 1 - $temp_flip;
      next;
    }
    
    last if $offset_position > $config->{'Subject_end'};

    $exon_feats_to_markup{$offset_position} = exists $exons->{$_}->{'overlap'} ? 'overlap' : 'exon';
  }
  
  my @markup_positions = sort { $a <=> $b } keys %exon_feats_to_markup;
  my $next_markup_pos  = shift @markup_positions;
  
  while ($actual_index < $config->{'length'}) {
    my $base = $sequence[$actual_index];
    
    if ($base ne '-') {
      if ($seq_index == $next_markup_pos) {
        my $markup_type = $exon_feats_to_markup{$seq_index}; 
        
        $flip            = 1 - $flip  if $markup_type eq 'exon';
        $style           = $markup_type eq 'overlap' ? 'exon2' : "exon$flip";
        $next_markup_pos = shift @markup_positions || undef;
      } else {
        $style = "exon$flip";
      }
      
      push @{$markup->{'exons'}{$actual_index}{'type'}}, $style;
      
      $seq_index++;
    }
    
    $actual_index++;
  }
}

sub set_variations {
  my ($self, $config, $sl, $markup, $transcript, $seq) = @_;
  my $seq_index  = $config->{'Subject_start'};
  my $actual_pos = $seq_index;
  my @seq        = split '', $seq;
  my $end        = $config->{'Subject_end'};
  my $seq_pos    = 0;
  my $position;
  
  while ($seq_index <= $end) {
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
  
  foreach my $snp (reverse @{$transcript->variation_data($transcript->translation_object->get_Slice, undef, $transcript->Obj->strand)}) {
    my $temp_pos = $snp->{'position'};
    
    next if $temp_pos < $config->{'Subject_start'} || $temp_pos > $config->{'Subject_end'};
    
    my $pos  = $position->{$temp_pos};
    my $dbID = $snp->{'vdbid'};
    
    $markup->{'variants'}{$pos}{'type'}    = lc($config->{'consequence_filter'} ? [ grep $config->{'consequence_filter'}{$_}, @{$snp->{'tv'}->consequence_type} ]->[0] : $snp->{'type'});
    $markup->{'variants'}{$pos}{'alleles'} = $snp->{'allele'};
    $markup->{'variants'}{$pos}{'href'} ||= {
      type        => 'ZMenu',
      action      => 'TextSequence',
      factorytype => 'Location'
    };

    push @{$markup->{'variants'}{$pos}{'href'}{'v'}},  $snp->{'snp_id'};
    push @{$markup->{'variants'}{$pos}{'href'}{'vf'}}, $dbID;
  }
}

sub markup_line_numbers {
  my ($self, $sequence, $config) = @_;
  my $blast_method = $self->blast_method;
  my $n            = 0; # Keep track of which element of $sequence we are looking at
  
  foreach my $sl (@{$config->{'slices'}}) {
    my $slice = $sl->{'slice'};
    
    $n++ and next unless $slice;
    
    my $name           = $sl->{'name'};
    my $seq            = $sl->{'seq'} || $slice->seq;
    my $rev            = $name eq 'Subject' ? $config->{'Subject_ori'} != 1 : undef;
    my $seq_offset     = 0;
    my $multiplication = ($blast_method eq 'TBLASTN' && $name eq 'Subject') || ($blast_method eq 'BLASTX' && $name eq 'Query') ? 3 : 1;
    
    my $data = {
      dir   => 1,
      start => $config->{"${name}_start"},
      end   => $config->{"${name}_end"},
    };
    
    my ($s, $loop_end) = $rev ? ($data->{'end'}, $data->{'start'}) : ($data->{'start'}, $data->{'end'});
    my $e              = $s - 1;
    my $start          = $data->{'start'};
    
    while ($s < $loop_end) {
      if ($e + ($config->{'display_width'} * $multiplication)  > $loop_end) {
        $e = $loop_end;
      } else {
        $e += $config->{'display_width'} * $multiplication;
      }
      
      my @bases       = split '', substr $seq, $seq_offset, $e >= $loop_end ? $e - $s + 1 : $config->{'display_width'};
      my $gap_count   = grep /-/, @bases;
      my $num_matches = (scalar @bases - $gap_count) * $multiplication;
      my $end;
      
      if ($rev) {
        $end = $start - $num_matches + 1;
        $end = $data->{'end'} if $end < $data->{'end'};
      } else { 
        $end = $e >= $data->{'end'} ? $data->{'end'} : $start + $num_matches -1;
        $end = $data->{'end'} if $end > $data->{'end'};
      }
      
      push @{$config->{'line_numbers'}{$n}}, { start => $start, end => $end };
      $config->{'padding'}{'number'} = length $s if length $s > $config->{'padding'}{'number'};
      
      ($start, $e) = $rev ? ($end - 1, $e + $gap_count) : ($end + 1, $e - $gap_count);
      $s           = $e + 1;
      $seq_offset += $config->{'display_width'};
    }
    
    $n++;
  }
}

1;
