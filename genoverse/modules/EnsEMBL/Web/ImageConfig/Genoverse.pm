=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use parent qw(EnsEMBL::Web::ImageConfig);

sub init_genoverse {
  my $self = shift;
  
  $self->set_parameter('component', $self->hub->viewconfig->component) if $self->hub->viewconfig;
  $self->create_menus('options');
  $self->add_option('auto_height', undef, undef, undef, 'off')->set('menu', 'no');
  
  $self->modify_configs($self->{'transcript_types'},                        { genoverse => { type   => 'Gene'                                                     } });
  $self->modify_configs([ 'misc_feature'                                 ], { genoverse => { type   => 'Clone'                                                    } });
  $self->modify_configs([ 'marker'                                       ], { genoverse => { type   => 'Marker'                                                   } });
  $self->modify_configs([ 'chr_band_core'                                ], { genoverse => { type   => 'ChrBand',             cache    => 'chr'                   } });
  $self->modify_configs([ 'contig'                                       ], { genoverse => { type   => 'Contig',              cache    => 'chr'                   } });
  $self->modify_configs([ 'assembly_exception_core', 'annotation_status' ], { genoverse => { type   => 'Patch',               cache    => 'chr'                   } });
  $self->modify_configs([ 'synteny'                                      ], { genoverse => { type   => 'Synteny',             cache    => 'chr'                   } });
  $self->modify_configs([ 'seq'                                          ], { genoverse => { type   => 'Sequence',            bin_size => 5e4, all_features => 1  } });  
  $self->modify_configs([ 'codonseq'                                     ], { genoverse => { type   => 'TranslatedSequence',  bin_size => 6e4, all_features => 1  } });
  $self->modify_configs([ 'codons'                                       ], { genoverse => { type   => 'Codons',              bin_size => 6e4,                    } });
  $self->modify_configs([ 'reg_features'                                 ], { genoverse => { type   => 'RegulatoryFeature',   bin_size => 1e6, threshold => 2.5e6 } });
  $self->modify_configs([ 'seg_features'                                 ], { genoverse => { type   => 'SegmentationFeature', bin_size => 2e6, threshold => 1e6   } });
  $self->modify_configs([ 'variation', 'somatic_mutation'                ], { genoverse => { type   => 'Variation',           bin_size => 1e6, threshold => 1e5   } });
  $self->modify_configs([ 'variation_feature_structural_smaller'         ], { genoverse => { type   => 'StructuralVariation', bin_size => 1e6, threshold => 5e6   } });
  $self->modify_configs([ map "${_}structural_variation", '', 'somatic_' ], { genoverse => { type   => 'StructuralVariation',                  threshold => 5e6   } });
  $self->modify_configs([ 'scalebar', 'ruler', 'draggable', 'info'       ], { genoverse => { remove => 1                                                          } });
  $self->modify_configs([ 'gencode'                                      ], { genoverse => { type   => 'Gene'                                                     } });  
  my $info  = $self->get_node('information');
  my $order = 1e6;
  
  # Super-horrible way of getting legend info from track ids
  for (grep { $_->get('menu') ne 'no' && $_->id =~ /legend/ } $info ? $info->nodes : ()) {
    (my $type = $_->id) =~ s/(fg_|_legend)//g;
    $type =~ s/features$/feature/;
    $type =~ s/_(\w)/uc $1/ge;
    $_->set('genoverse', { type => 'Legend', featureType => ucfirst $type, order => $order++ });
  }
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
      $config{'stranded'} = JSON::true;
      $_->set('genoverse', \%config);
    }
  }
  
  return $self->{'ordered_tracks'};
}

# Don't reset auto height setting
sub reset {
  my $self = shift;
  
  if ($self->hub->input->param('reset') ne 'track_order') {
    my $user_data = $self->get_user_settings;
    
    foreach my $track (keys %$user_data) {
      foreach (keys %{$user_data->{$track}}) {
        next if /^(display|track_order)$/;
        $self->altered = 1 if delete $user_data->{$track}{$_};
      }
    }
  }
  
  $self->SUPER::reset;
}

1;
