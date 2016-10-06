package EnsEMBL::Web::TextSequence::View::AlignmentProtein;

use EnsEMBL::Web::TextSequence::Annotation::Sequence;
use EnsEMBL::Web::TextSequence::Annotation::BLAST::AlignmentProtein::Exons;
use EnsEMBL::Web::TextSequence::Annotation::BLAST::AlignmentProtein::Variations;
use EnsEMBL::Web::TextSequence::Markup::BLAST::AlignmentProtein::LineNumbers;

use parent qw(EnsEMBL::Web::TextSequence::View::Alignment);

# XXX into subclasses
sub set_annotations {
  my ($self,$config) = @_;

  $self->SUPER::set_annotations($config);
  $self->add_annotation(EnsEMBL::Web::TextSequence::Annotation::BLAST::AlignmentProtein::Exons->new);
  $self->add_annotation(EnsEMBL::Web::TextSequence::Annotation::BLAST::AlignmentProtein::Variations->new([0,2]));
}

sub set_markup {
  my ($self,$config) = @_;

  $self->SUPER::set_markup($config);
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::BLAST::AlignmentProtein::LineNumbers->new) if $config->{'exon_display'};
}

1;
