package EnsEMBL::Web::Component::Tools::Blast::QuerySeq;

use strict;

use Bio::EnsEMBL::Slice;

use base qw(EnsEMBL::Web::Component::Tools::Blast::TextSequence);

sub initialize {
  my ($self, $slice, $start, $end) = @_;
  my $hub    = $self->hub;
  my $config = {
    display_width   => $hub->param('display_width') || 60,
    species         => $self->job->job_data->{'species'},
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
  my $job_data  = $self->job->job_data;
  my $hit       = $self->hit;
  my $query_seq = $job_data->{'sequence'}{'seq'};
  
  return Bio::EnsEMBL::Slice->new(
    -coord_system    => $self->object->get_hit_genomic_slice($hit, $job_data->{'species'})->coord_system,
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
  
  return $self->SUPER::get_key($config, {
    hsp => {
      sel   => { class => 'hsp_sel',   order => 1, text => 'Matching bases for selected HSP' },
      other => { class => 'hsp_other', order => 2, text => 'Matching bases for other HSPs in selected hit' }
    }
  });
}

1;
