package EnsEMBL::Web::TextSequence::Markup::BLAST::AlignmentProtein::LineNumbers;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::TextSequence::Markup);

sub replaces { return 'EnsEMBL::Web::TextSequence::Markup::BLAST::AlignmentLineNumbers'; }

# XXX how exactly /is/ this different to the main method?
sub markup {
  my ($self, $sequence, $markup, $config) = @_;

  my $blast_method = $config->{'blast_method'};
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
