=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Blast::QuerySeq;

use strict;

use Bio::EnsEMBL::Slice;

use parent qw(EnsEMBL::Web::Component::Tools::Blast::TextSequence);

sub initialize {
  my ($self, $slice, $start, $end) = @_;
  my $hub    = $self->hub;
  my $config = {
    display_width   => $hub->param('display_width') || 60,
    species         => $self->job->species,
    sub_slice_start => $start,
    sub_slice_end   => $end
  };
  
  for (qw(line_numbering hsp_display)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off';
  }
  
  $config->{'slices'}     = [{ slice => $slice || $self->get_slice, name => $config->{'species'} }];
  $config->{'end_number'} = $config->{'number'} = 1 if $config->{'line_numbering'};
  
  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);
  
  $self->markup_hsp($sequence, $markup, $config) if $config->{'hsp_display'};
  $self->markup_line_numbers($sequence, $config) if $config->{'line_numbering'};
  
  return ($sequence, $config);
}

sub get_slice {
  my $self      = shift;
  my $job       = $self->job;
  my $hit       = $self->hit;
  my $query_seq = $self->object->get_input_sequence_for_job($job)->{'sequence'};
  
  return Bio::EnsEMBL::Slice->new(
    -coord_system    => $self->object->get_hit_genomic_slice($hit)->coord_system,
    -seq_region_name => $hit->{'qid'},
    -start           => 1,
    -end             => length($query_seq),
    -strand          => $hit->{'qori'},
    -seq             => $query_seq
  );
}

sub get_slice_name { return join ':', $_[1]->seq_region_name, $_[1]->start, $_[1]->end, $_[1]->strand; }

sub get_key {
  ## @override
  ## Adds the HSP key before calling the base class's method
  my ($self, $config) = @_;

  my $type = $self->job->job_data->{query_type} eq 'peptide' ? 'residues' : 'bases';
  
  return $self->SUPER::get_key($config, {
    hsp => {
      sel   => { class => 'hsp_sel',   order => 1, text => "Matching $type for selected HSP" },
      other => { class => 'hsp_other', order => 2, text => "Matching $type for other HSPs in selected hit" }
    }
  });
}

1;
