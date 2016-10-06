package EnsEMBL::Web::TextSequence::Annotation::BLAST::AlignmentProtein::Exons;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::TextSequence::Annotation);

sub replaces { return 'EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Exons'; }

sub annotate {
  my ($self, $config, $sl, $markup, $seq) = @_; 

  # XXX doesn't belong here: for tools, method should never be called
  return if $config->{'source_type'} =~ /latestgp/i or $sl->{'no_markup'};
  warn "C\n";
  my $exons        = $sl->{'transcript'}->peptide_splice_sites;
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

1;
