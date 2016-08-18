package EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Variations;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::TextSequence::Annotation::Variations);

sub replaces { return 'EnsEMBL::Web::TextSequence::Annotation::Variations'; }

sub annotate {
  my ($self, $config, $sl, $markup, $seq, $hub,$sequence) = @_;

  # XXX should not be here!
  return if $sl->{'no_markup'};

  return $self->SUPER::annotate($config, $sl, $markup, $seq, $hub,$sequence);
}

1;
