package EnsEMBL::Web::TextSequence::View::QuerySeq;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::TextSequence::View::BLAST);

use EnsEMBL::Web::TextSequence::Markup::LineNumbers;
use EnsEMBL::Web::TextSequence::Markup::BLAST::HSP;

sub set_markup {
  my ($self,$config) = @_; 

  $self->SUPER::set_markup($config);
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::LineNumbers->new) if $config->{'line_numbering'} ne 'off';
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::BLAST::HSP->new) if $config->{'hsp_display'} ne 'off';
}

1;
