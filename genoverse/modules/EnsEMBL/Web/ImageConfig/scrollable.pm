# $Id$

package EnsEMBL::Web::ImageConfig::scrollable;

use strict;

use JSON;

use base qw(EnsEMBL::Web::ImageConfig::Genoverse);

sub init {
  my $self = shift;
  
  $self->set_parameters({
    sortable_tracks  => 'drag',
    opt_empty_tracks => 0,
    toolbars         => { top => 1, bottom => 1 }
  });
  
  $self->create_menus(qw(
    sequence
    marker
    transcript
    misc_feature
    synteny
    variation
    somatic
    decorations
    information
  ));
  
  my @seq  = qw(contig seq codonseq codons);
  my %desc = (
    contig   => 'Track showing underlying assembly contigs.',
    seq      => 'Track showing sequence in both directions. Only displayed at 1Kb and below.',
    codonseq => 'Track showing 6-frame translation of sequence. Only displayed at 1Kb and below.',
    codons   => 'Track indicating locations of start and stop codons in region. Only displayed at 5Kb and below.'
  );
  
  $self->add_tracks('sequence',
    [ $seq[0], 'Contigs',             $seq[0],    { display => 'normal', strand => 'f', description => $desc{$seq[0]} }],
    [ $seq[1], 'Sequence',            'sequence', { display => 'normal', strand => 'b', description => $desc{$seq[1]}, colourset => $seq[1], threshold => 1 }],
    [ $seq[2], 'Translated sequence', $seq[2],    { display => 'off',    strand => 'b', description => $desc{$seq[2]}, colourset => $seq[2], threshold => 1 }],
    [ $seq[3], 'Start/stop codons',   $seq[3],    { display => 'off',    strand => 'b', description => $desc{$seq[3]}, colourset => $seq[3], threshold => 5 }],
  );
  
  $self->load_tracks;
  
  $_->set('display', 'gene_label') for grep $_->id =~ /transcript_[core|vega_update]/, $self->get_node('transcript')->nodes;
  
  $self->modify_configs([ 'transcript' ], { strand => 'r' });
  $self->modify_configs([ 'variation', 'somatic' ], { display => 'off', menu => 'no' });
  $self->modify_configs([ 'variation_feature_variation', 'variation_feature_structural', 'somatic_sv_feature', 'somatic_mutation_all' ], { menu => 'yes' });
  
  $self->init_genoverse;
}

1;
