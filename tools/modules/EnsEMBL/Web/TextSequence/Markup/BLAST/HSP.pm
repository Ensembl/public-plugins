package EnsEMBL::Web::TextSequence::Markup::BLAST::HSP;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::TextSequence::Markup);

sub markup {
  my ($self, $sequence, $markup, $config) = @_; 

  my %hsp_types; 
  my $i = 0;

  foreach my $data (@$markup) {
    my $seq = $sequence->[$i]->legacy;

    foreach (sort { $a <=> $b } keys %{$data->{'hsps'}}) {
      my $hsp = $data->{'hsps'}{$_};

      next unless $hsp->{'type'};

      my %types = map { $_ => 1 } @{$hsp->{'type'}};
      my $type  = $types{'sel'} ? 'sel' : 'other'; # Both types are denoted by foreground colour, so only mark the more important type 

      $seq->[$_]{'class'} = join ' ', "hsp_$type", $seq->[$_]{'class'} || () unless ($seq->[$_]{'class'} || '') =~ /\bhsp_$type\b/;
      $hsp_types{"hsp_$type"}   = 1;
    }     

    $i++;
  }

  $config->{'key'}{'HSP'}{$_} = 1 for keys %hsp_types;
}

1;
