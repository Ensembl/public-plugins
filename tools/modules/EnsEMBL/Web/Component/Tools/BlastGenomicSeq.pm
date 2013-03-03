package EnsEMBL::Web::Component::Tools::BlastGenomicSeq;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Tools);


sub _init {
  my $self = shift;
  my $hub = $self->hub;

  $self->cacheable(0);
  $self->ajaxable(1);

  $self->{'subslice_length'} = $hub->param('force') || 5000 * ($hub->param('display_width') || 60);
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
    title_display   => 'yes',
    sub_slice_start => $start,
    sub_slice_end   => $end,
    ambiguity       => 1,
  };

  for (qw(exon_display exon_ori snp_display line_numbering hsp_display codons_display title_display)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off';
  }

  $config->{'exon_display'} = 'selected' if $config->{'exon_ori'};
  $config->{'slices'} = [{ slice => $slice, name => $config->{'species'} }];

  if ($config->{'line_numbering'}) {
    $config->{'end_number'} = 1;
    $config->{'number'} = 1;
  }

  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);

  $self->markup_hsp($sequence, $markup, $config)        if $config->{'hsp_display'};
  $self->markup_exons($sequence, $markup, $config)      if $config->{'exon_display'};
  $self->markup_variation($sequence, $markup, $config)  if $config->{'snp_display'};
  $self->markup_line_numbers($sequence, $config)        if $config->{'line_numbering'};
  $self->markup_codons($sequence, $markup, $config)     if $config->{'codons_display'};  

  return ($sequence, $config);
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $hub = $self->hub;
  my $result_id = $hub->param('res');
 
  my $species = $object->get_hit_species($result_id);
  my $genomic_slice = $self->slice;
  my $length    = $genomic_slice->length;

  my $html      = $self->tool_buttons(uc $genomic_slice->seq(1), $species);

  if ($length >= $self->{'subslice_length'}) {
    $html .= '<div class="sequence_key"></div>' . $self->chunked_content($length, $self->{'subslice_length'}, { length => $length, name => $genomic_slice->name });
  } else {
    $html .= $self->content_sub_slice($genomic_slice); # Direct call if the sequence length is short enough
  }
  
  return $html;
}

sub slice {
  my $self = shift;
  my $object = $self->object;
  my $hub = $self->hub;
  my ($flank5, $flank3) = map $self->hub->param($_), qw(flank5_display flank3_display);
  my $result_id = $hub->param('res');

  my $genomic_hit = $object->fetch_blast_hit_by_id($result_id);
  my $species = $object->get_hit_species($result_id);
  my $genomic_slice = $self->object->get_hit_genomic_slice($genomic_hit, $species, $flank5, $flank3,);
  my $ori = $hub->param('orientation');
  my $g_ori = $genomic_hit->{'gori'};   
  my $q_ori = $genomic_hit->{'qori'};
  my $invert_flag;

  if ( ($q_ori eq '1' && $g_ori eq '1') && $ori eq 'rc'){
    $invert_flag = 1;
  } elsif ( ($q_ori eq '1' && $g_ori eq '-1') && $ori eq 'fc'){ 
    $invert_flag = 1;
  } elsif ( ($q_ori eq '-1' && $g_ori eq '1') && $ori ne 'fc'){
    $invert_flag = 1;
  } elsif ( ($q_ori eq '-1' && $g_ori eq '-1') && $ori ne 'rc'){
    $invert_flag = 1;
  } 

  if ($invert_flag ){ $genomic_slice = $genomic_slice->invert; } 

  return $genomic_slice;
}

sub content_sub_slice {
  my ($self, $slice) = @_;
  my $hub    = $self->hub;
  my $start  = $hub->param('subslice_start'); 
  my $end    = $hub->param('subslice_end'); 
  my $length = $hub->param('length'); 

  $slice   ||= $self->slice;
  $slice   = $slice->sub_Slice($start, $end) if $start && $end;

  my ($sequence, $config) = $self->initialize($slice, $start, $end);

  if ($start == 1) {
    $config->{'html_template'} = qq{<pre class="text_sequence" style="margin-bottom:0">&gt;} . $hub->param('name') . "\n%s</pre>";
  } elsif ($end && $end == $length) {
    $config->{'html_template'} = '<pre class="text_sequence">%s</pre>';
  } elsif ($start && $end) {
    $config->{'html_template'} = '<pre class="text_sequence" style="margin:0 0 0 1em">%s</pre>';
  } else {
    $config->{'html_template'} = sprintf('<div class="sequence_key">%s</div>', $self->get_key($config)) . '<pre class="text_sequence">&gt;' . $slice->name . "\n%s</pre>";
  }
 
  $config->{'html_template'} .= '<p class="invisible">.</p>';

  return $self->build_sequence($sequence, $config);
}
1;
