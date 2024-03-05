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

package EnsEMBL::Web::TextSequence::View::Alignment;

use strict;
use warnings;

use File::Basename;

use EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Exons;
use EnsEMBL::Web::TextSequence::Annotation::BLAST::Alignment::Variations;
use EnsEMBL::Web::TextSequence::Annotation::BLAST::HSP;

use EnsEMBL::Web::TextSequence::Markup::Exons;
use EnsEMBL::Web::TextSequence::Markup::Variations;
use EnsEMBL::Web::TextSequence::Markup::Comparisons;
use EnsEMBL::Web::TextSequence::Markup::BLAST::AlignmentLineNumbers;

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
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::Variations->new([0,2]));
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::Comparisons->new);
  $self->add_markup(EnsEMBL::Web::TextSequence::Markup::BLAST::AlignmentLineNumbers->new);
}

1;
