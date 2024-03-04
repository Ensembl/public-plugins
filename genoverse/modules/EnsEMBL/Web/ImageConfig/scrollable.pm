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

package EnsEMBL::Web::ImageConfig::scrollable;

use strict;

use parent qw(EnsEMBL::Web::ImageConfig::Genoverse);

sub init_cacheable {
  my $self = shift;
  
  $self->set_parameters({
    sortable_tracks  => 'drag',
    opt_empty_tracks => 0,
    top_toolbar      => 1,
    bottom_toolbar   => 1,
  });
  
  $self->create_menus(qw(
    sequence
    marker
    transcript
    misc_feature
    synteny
    functional
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
  
  $_->set_data('display', 'gene_label') for grep $_->id =~ /transcript_core/, @{$self->get_node('transcript')->get_all_nodes};
  
  $self->modify_configs([ 'transcript' ], { strand => 'r' });
  $self->modify_configs([ 'variation', 'somatic', 
                          'fg_multi_wiggle_legend', 'fg_methylation_legend', 
                          'functional_other_regulatory_regions', 'functional_dna_methylation',
                          'reg_features', 'seg_features', 'reg_feats_core', 'reg_feats_non_core' ], 
                              { display => 'off', menu => 'no' });
  $self->modify_configs([ map("variation_feature_$_", qw(variation structural_larger structural_smaller)), qw(somatic_sv_feature somatic_mutation_all) ], { menu => 'yes' });
 
  ## Regulatory build track now needs to be turned on explicitly
  $self->modify_configs(['regbuild'], {display => 'compact', menu => 'yes'});
 
  $self->init_genoverse;
}

1;
