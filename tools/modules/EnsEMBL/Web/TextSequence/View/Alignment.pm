package EnsEMBL::Web::TextSequence::View::Alignment;

use EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Exons;
use EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Variations;
use EnsEMBL::Web::TextSequence::Annotation::BLAST::HSP;

use EnsEMBL::Web::TextSequence::Markup::Exons;
use EnsEMBL::Web::TextSequence::Markup::Comparisons;
use EnsEMBL::Web::TextSequence::Markup::Variations;
use EnsEMBL::Web::TextSequence::Markup::LineNumbers;

use parent qw(EnsEMBL::Web::TextSequence::View::BLAST);

# XXX into subclasses
sub set_annotations {
  my ($self,$config) = @_;

  $self->SUPER::set_annotations($config);
  $self->add_annotation(EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Exons->new);
  $self->add_annotation(EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Variations->new([0,2]));
  $self->add_annotation(EnsEMBL::Web::TextSequence::Annotation::BLAST::HSP->new) if $config->{'hsp_display'};
}

sub set_markup {
  my ($self,$config) = @_; 

  $self->SUPER::set_markup($config);
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::Exons->new) if $config->{'exon_display'};
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::Variations->new([0,2])) if $config->{'snp_display'};
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::Comparisons->new);
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::LineNumbers->new) if $config->{'line_numbering'} ne 'off';
}

1;
