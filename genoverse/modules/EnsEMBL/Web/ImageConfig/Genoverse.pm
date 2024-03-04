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

package EnsEMBL::Web::ImageConfig::Genoverse;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ImageConfig);

sub init_genoverse {
  my $self  = shift;
  my $hub   = $self->hub;
  my $vc    = $hub->get_viewconfig({component => 'ViewTop', type => 'Location'});

  $self->set_parameter('component', $vc->component) if $vc;
  $self->create_menus('options');
  $self->add_option('options', 'auto_height', undef, $hub->species_defs->GENOVERSE_TRACK_AUTO_HEIGHT ? 'normal' : 'off', undef, undef, {'menu' => 'no'});
  
  $self->modify_configs([$self->_transcript_types],                         { genoverse => { type   => 'Gene'                                                     } });
  $self->modify_configs([ 'misc_feature'                                 ], { genoverse => { type   => 'Clone'                                                    } });
  $self->modify_configs([ 'marker'                                       ], { genoverse => { type   => 'Marker'                                                   } });
  $self->modify_configs([ 'chr_band_core'                                ], { genoverse => { type   => 'ChrBand',             cache    => 'chr'                   } });
  $self->modify_configs([ 'contig'                                       ], { genoverse => { type   => 'Contig',              cache    => 'chr'                   } });
  $self->modify_configs([ 'assembly_exception_core', 'annotation_status' ], { genoverse => { type   => 'Patch',               cache    => 'chr'                   } });
  $self->modify_configs([ 'synteny'                                      ], { genoverse => { type   => 'Synteny',             cache    => 'chr'                   } });
  $self->modify_configs([ 'seq'                                          ], { genoverse => { type   => 'Sequence',            bin_size => 5e4, all_features => 1  } });  
  $self->modify_configs([ 'codonseq'                                     ], { genoverse => { type   => 'TranslatedSequence',  bin_size => 6e4, all_features => 1  } });
  $self->modify_configs([ 'codons'                                       ], { genoverse => { type   => 'Codons',              bin_size => 6e4,                    } });
  $self->modify_configs([ 'regbuild'                                     ], { genoverse => { type   => 'RegulatoryFeature',   bin_size => 1e6, threshold => 2.5e6 } });
  $self->modify_configs([ 'variation', 'somatic_mutation'                ], { genoverse => { type   => 'Variation',           bin_size => 1e6, threshold => 1e5   } });
  $self->modify_configs([ 'variation_feature_structural_smaller'         ], { genoverse => { type   => 'StructuralVariation', bin_size => 1e6, threshold => 5e6   } });
  $self->modify_configs([ map "${_}structural_variation", '', 'somatic_' ], { genoverse => { type   => 'StructuralVariation',                  threshold => 5e6   } });
  $self->modify_configs([ 'scalebar', 'ruler', 'draggable', 'info'       ], { genoverse => { remove => 1                                                          } });
  $self->modify_configs([ 'gencode'                                      ], { genoverse => { type   => 'Gene'                                                     } });  
  $self->modify_configs([ 'mane_select'                                  ], { display => 'off'                                                                      });

  my $info = $self->get_node('information');

  # Remove all information tracks including legends (Genoverse creates them by reading all track features) but keep 'options'.
  $_->remove for grep $_->get_data('node_type') ne 'option', $info ? @{$info->get_all_nodes} : ();
}

# All functions from here on are generic modifications
sub _glyphset_tracks {
  my $self = shift;
  
  if (!$self->{'_glyphset_tracks'}) {
    my %stranded;
    
    $self->SUPER::glyphset_tracks;
    
    push @{$stranded{$_->id}}, $_ for @{$self->{'_glyphset_tracks'}};
    
    foreach (map scalar @$_ == 2 ? @$_ : (), values %stranded) {
      my %config = %{$_->get_data('genoverse') || {}};
      $config{'stranded'} = JSON::true;
      $_->set_data('genoverse', \%config);
    }
  }
  
  return $self->{'_glyphset_tracks'};
}

# Don't reset auto height setting
sub reset_genoverse {
  my $self = shift;
  
  if ($self->hub->input->param('reset') ne 'track_order') {
    my $user_data = $self->get_user_settings;
    
    foreach my $track (keys %{$user_data->{'nodes'}}) {
      foreach (keys %{$user_data->{$track}}) {
        next if /^(display|track_order)$/;
        $self->altered($track) if delete $user_data->{$track}{$_};
      }
    }
  }
  
  $self->SUPER::reset;
}

sub reset {
  return shift->reset_genoverse(@_);
}

1;
