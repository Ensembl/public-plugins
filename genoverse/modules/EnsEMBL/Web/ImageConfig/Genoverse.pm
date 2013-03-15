# $Id$

package EnsEMBL::Web::ImageConfig::Genoverse;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init_genoverse {
  my $self = shift;
  
  $self->set_parameter('component', $self->hub->viewconfig->component) if $self->hub->viewconfig;
  $self->create_menus('options');
  $self->add_option('auto_height', undef, undef, undef, 'off')->set('menu', 'no');
  
  $self->modify_configs($self->{'transcript_types'},                        { genoverse => { type       => 'Gene'                                                                                                 } });
  $self->modify_configs([ 'misc_feature'                                 ], { genoverse => { type       => 'Clone'                                                                                                } });
  $self->modify_configs([ 'contig'                                       ], { genoverse => { type       => 'Contig',              cache          => 'chr'                                                         } });
  $self->modify_configs([ 'assembly_exception_core', 'annotation_status' ], { genoverse => { type       => 'Patch',               cache          => 'chr'                                                         } });
  $self->modify_configs([ 'synteny'                                      ], { genoverse => { type       => 'Synteny',             cache          => 'chr',       cache_id      => 'synteny'                       } });
  $self->modify_configs([ 'seq'                                          ], { genoverse => { type       => 'Sequence',            bin_size       => 5e4,         all_features  => 1                               } });  
  $self->modify_configs([ 'codonseq'                                     ], { genoverse => { type       => 'TranslatedSequence',  bin_size       => 5e4,         all_features  => 1                               } });
  $self->modify_configs([ 'variation', 'somatic_mutation'                ], { genoverse => { type       => 'Variation',           threshold      => 1e5,         bin_size      => 1e6                             } });
  $self->modify_configs([ map "${_}structural_variation", '', 'somatic_' ], { genoverse => { type       => 'StructuralVariation', threshold      => 5e6                                                           } });
  $self->modify_configs([ 'variation_legend'                             ], { genoverse => { type       => 'Legend',              featureType    => 'Variation', order         => 1e6                             } });
  $self->modify_configs([ 'gene_legend'                                  ], { genoverse => { type       => 'Legend',              featureType    => 'Gene',      order         => 2e6                             } });
  $self->modify_configs([ 'codons'                                       ], { genoverse => { autoHeight => 'force',               bin_size       => 5e4,         featureHeight => 3,                              } });
  $self->modify_configs([ 'chr_band_core'                                ], { genoverse => { autoHeight => 'force',               cache          => 'chr',       allData       => JSON::true, labels => 'overlay' } });
  $self->modify_configs([ 'marker'                                       ], { genoverse => { bump       => 'labels',              maxLabelRegion => 5e4                                                           } });
  $self->modify_configs([ 'scalebar', 'ruler', 'draggable', 'info'       ], { genoverse => { remove     => 1                                                                                                      } });
  
  my $node = $self->get_node('marker');
  $_->set('genoverse', { bump => JSON::true, labels => 'overlay' }) for grep $_->id =~ /^qtl_/, $node ? $node->nodes : ();
}

# All functions from here on are generic modifications
sub glyphset_configs {
  my $self = shift;
  
  if (!$self->{'ordered_tracks'}) {
    my %stranded;
    
    $self->SUPER::glyphset_configs;
    
    push @{$stranded{$_->id}}, $_ for @{$self->{'ordered_tracks'}};
    
    foreach (map scalar @$_ == 2 ? @$_ : (), values %stranded) {
      my %config = %{$_->get('genoverse') || {}};
      push @{$config{'inherit'}}, 'Stranded';
      $_->set('genoverse', \%config);
    }
  }
  
  return $self->{'ordered_tracks'};
}

# Don't reset auto height setting
sub reset {
  my $self        = shift;
  my $auto_height = $self->get_node('auto_height');
  my $value       = $auto_height->get('display');
  
  $self->SUPER::reset;
  $auto_height->set_user('display', $value);
}

1;
