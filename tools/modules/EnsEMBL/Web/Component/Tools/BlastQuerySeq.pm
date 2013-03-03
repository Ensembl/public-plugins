package EnsEMBL::Web::Component::Tools::BlastQuerySeq;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Tools);
use Bio::EnsEMBL::Slice;

sub _init {
  my $self = shift;
  my $hub = $self->hub;

  $self->cacheable(0);
  $self->ajaxable(1);

  $self->{'subslice_length'} = $hub->param('force') || 5000 * ($hub->param('display_width') || 60);
#$self->{'subslice_length'} = $hub->param('force') || 5 * ($hub->param('display_width') || 60);
}


sub initialize {
  my ($self, $slice, $start, $end) = @_;
  my $hub    = $self->hub;
  my $object = $self->object;
  my $result_id = $hub->param('res');
  my $species = $object->get_hit_species($result_id);


  my $config = {
    display_width   => $hub->param('display_width') || 60,
    site_type       => ucfirst(lc $hub->species_defs->ENSEMBL_SITETYPE) || 'Ensembl',
    species         => $species,
    sub_slice_start => $start,
    sub_slice_end   => $end
  };

  for (qw(line_numbering hsp_display)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off';
  }

  $config->{'slices'} = [{ slice => $slice, name => $config->{'species'} }];

  if ($config->{'line_numbering'}) {
    $config->{'end_number'} = 1;
    $config->{'number'} = 1;
  }

  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);

  $self->markup_hsp($sequence, $markup, $config) if $config->{'hsp_display'};
  $self->markup_line_numbers($sequence, $config)       if $config->{'line_numbering'};

  return ($sequence, $config);
}

sub content {
  my $self = shift;
  
  my $query_slice = $self->query_slice; 
  my $species = $self->object->get_hit_species($self->hub->param('res'));
  my $length = $query_slice->length();

  my $html      = $self->tool_buttons(uc $query_slice->seq(1), $species);

  if ($length >= $self->{'subslice_length'}) {
    my $base_url = $self->ajax_url('sub_slice', { length => $length, name => $query_slice->name });
    $html .= '<div class="sequence_key"></div>' . $self->chunked_content($length, $self->{'subslice_length'}, $base_url);
  } else {
    $html .= $self->content_sub_slice($query_slice); # Direct call if the sequence length is short enough
  }

  return $html;
}

sub query_slice {
  my $self = shift;
  my $object = $self->object;
  my $hub = $self->hub;
  my $species_defs = $hub->species_defs;
  my $ticket = $object->ticket;
  my $ticket_id = $ticket->ticket_id;
  my $hit_id = $hub->param('hit');
  my $result_id = $hub->param('res');

  my $hit = $object->fetch_blast_hit_by_id($result_id);
  my $query_sequence = $object->complete_query_sequence($hit);
  my $length = length($query_sequence);

  # This is a bit of a hack need to find a better way of doing this
  my $genomic_hit = $object->fetch_blast_hit_by_id($result_id);
  my $species = $object->get_hit_species($result_id);
  my $genomic_slice = $self->object->get_hit_genomic_slice($genomic_hit, $species);
  my $coord_system = $genomic_slice->coord_system;



  my $query_slice =  Bio::EnsEMBL::Slice->new(
    -coord_system    => $coord_system,
    -seq_region_name => $hit->{'qid'},
    -start        => 1,
    -end          => $length,
    -strand       => $hit->{'qori'},
    -seq          => $query_sequence
  );
    
  return $query_slice;
}

sub query_slice_name {
  my $self = shift;
  my $slice = $self->query_slice;
  return join(':',
              $slice->seq_region_name,
              $slice->start,
              $slice->end,
              $slice->strand
  );
}

sub content_sub_slice {
  my ($self, $slice) = @_;
  my $hub    = $self->hub;
  my $start  = $hub->param('subslice_start');
  my $end    = $hub->param('subslice_end');
  my $length = $hub->param('length');

  $slice = $self->query_slice if !$slice;
  $slice   = $slice->sub_Slice($start, $end) if $start && $end;

  my ($sequence, $config) = $self->initialize($slice, $start, $end);

  if ($start == 1) {
    $config->{'html_template'} = qq{<pre class="text_sequence" style="margin-bottom:0">&gt;} . $self->query_slice_name . "\n%s</pre>";
  } elsif ($end && $end == $length) {
    $config->{'html_template'} = '<pre class="text_sequence">%s</pre>';
  } elsif ($start && $end) {
    $config->{'html_template'} = '<pre class="text_sequence" style="margin:0 0 0 1em">%s</pre>';
  } else {
    $config->{'html_template'} = sprintf('<div class="sequence_key">%s</div>', $self->get_key($config)) . '<pre class="text_sequence">&gt;' . $self->query_slice_name . "\n%s</pre>";
  }

  $config->{'html_template'} .= '<p class="invisible">.</p>';

  return $self->build_sequence($sequence, $config);
}

1;

