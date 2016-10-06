package EnsEMBL::Web::TextSequence::Annotation::BLAST::AlignmentProtein::Variations;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::TextSequence::Annotation);

sub replaces { return 'EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Variations'; }

sub annotate {
  my ($self, $config, $sl, $markup, $seq, $hub,$sequence) = @_;

  # XXX should not be here!
  return if $config->{'source_type'} =~ /latestgp/i or $sl->{'no_markup'};

  my $transcript = $sl->{'transcript'};
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

1;
