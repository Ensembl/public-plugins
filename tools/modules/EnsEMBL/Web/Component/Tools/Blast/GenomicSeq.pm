=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Blast::GenomicSeq;

use strict;

use parent qw(EnsEMBL::Web::Component::Tools::Blast::TextSequence);

use EnsEMBL::Web::TextSequence::View::GenomicSeq;

sub initialize_new {
  my ($self, $slice, $start, $end) = @_;
  my $hub     = $self->hub;
  my $species = $self->job->species;
  my $config  = {
    display_width   => $hub->param('display_width') || 60,
    species         => $species,
    sub_slice_start => $start,
    sub_slice_end   => $end,
    ambiguity       => 1,
    factorytype     => 'Tools',
  };
  
  for ($self->viewconfig->options) {
    $config->{$_} = $self->param($_) unless $self->param($_) eq 'off';
  }
  
  $config->{'slices'} = [{ slice => $slice || $self->get_slice, name => $species }];
  
  if ($config->{'line_numbering'}) {
    $config->{'number'}     = 1;
  }
  $config->{'genomic'} = 1; # For styles
  
  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);
  $self->view->markup($sequence,$markup,$config);
  
  return ($sequence, $config);
}


sub get_slice {
  my $self  = shift;
  my $hub   = $self->hub;
  my $hit   = $self->hit;
  my $slice = $self->object->get_hit_genomic_slice($hit, $hub->param('flank5_display'), $hub->param('flank3_display'));
  my $ori   = $hub->param('orientation');
  my $g_ori = $hit->{'gori'};
  my $q_ori = $hit->{'qori'};
  
  if (
    ($q_ori ==  1 && $g_ori ==  1 && $ori eq 'rc') ||
    ($q_ori ==  1 && $g_ori == -1 && $ori eq 'fc') ||
    ($q_ori == -1 && $g_ori ==  1 && $ori ne 'fc') ||
    ($q_ori == -1 && $g_ori == -1 && $ori ne 'rc')
  ) {
    $slice = $slice->invert;
  }

  return $slice;
}

sub get_sequence_data {
  ## @override
  ## Add HSPs to the sequence data
  my ($self, $slices, $config) = @_;

  $config->{'hit'} = $self->hit;
  $config->{'job'} = $self->job;
  $config->{'object'} = $self->object;
  $config->{'slice_type'} = ref($self) =~ /QuerySeq$/ ? 'q' : 'g';
  my ($sequence, $markup) = $self->SUPER::get_sequence_data($slices, $config);

  return ($sequence, $markup);
}

sub make_view {
  my ($self) = @_;

  return EnsEMBL::Web::TextSequence::View::GenomicSeq->new($self->hub);
}

1;
