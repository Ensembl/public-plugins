package EnsEMBL::Web::TextSequence::Markup::BLAST::AlignmentLineNumbers;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::TextSequence::Markup::LineNumbers);

sub markup {
  my ($self, $sequence, $markup, $config) = @_; 

  $self->SUPER::markup($sequence,$markup,$config);

  foreach (map @$_, values %{$config->{'line_numbers'}}) {
    $config->{'padding'}{'pre_number'} = length $_->{'label'} if length $_->{'label'} > $config->{'padding'}{'pre_number'};
  }
}

1;
