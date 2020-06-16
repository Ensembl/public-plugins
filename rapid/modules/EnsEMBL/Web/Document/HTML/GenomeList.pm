=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::HTML::GenomeList;

use strict;
use warnings;

sub get_featured_genomes { return (); }

sub _species_list {
  ## @private
  my ($self, $params) = @_;

  $params   ||= {};
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $species = $hub->get_species_info;
  my $user    = $params->{'no_user'} ? undef : $hub->users_plugin_available && $hub->user;
  my $img_url = $sd->img_url || '';
  my @fav     = @{$hub->get_favourite_species(!$user)};
  my %fav     = map { $_ => 1 } @fav;

  my (@list, %done);

  for (@fav, sort {$species->{$a}{'scientific'} cmp $species->{$b}{'scientific'}} keys %$species) {

    next if ($done{$_} || !$species->{$_} || !$species->{$_}{'is_reference'});

    $done{$_} = 1;

    my $homepage      = $hub->url({'species' => $_, 'type' => 'Info', 'function' => 'Index', '__clear' => 1});
    my $alt_assembly  = $sd->get_config($_, 'SWITCH_ASSEMBLY');
    my $strainspage   = '';
    my $strain_type   = '';
#    if ($species->{$_}{'strain_group'}) {
#      $strainspage = $hub->url({'species' => $_, 'type' => 'Info', 'function' => 'Strains', '__clear' => 1});
#      $strain_type = $sd->get_config($_, 'STRAIN_TYPE').'s';
#    }

    push @list, { 
      key         => $_,
      group       => $species->{$_}{'group'},
      homepage    => $homepage,
      name        => $species->{$_}{'name'},
      img         => sprintf('%sspecies/%s.png', $img_url, $species->{$_}{'image'}),
      common      => $species->{$_}{'scientific'},
      assembly    => $species->{$_}{'assembly'},
      assembly_v  => $species->{$_}{'assembly_version'},
      favourite   => $fav{$_} ? 1 : 0,
      strainspage => $strainspage,
      strain_type => $strain_type, 
      has_alt     => $alt_assembly ? 1 : 0,
      extra       => '',
    };

  }

  return \@list;
}




sub _get_dom_tree {
  ## @private
  my $self      = shift;
  my $hub       = $self->hub;
  my $sd        = $hub->species_defs;
  my $species   = $self->_species_list({'no_user' => 1});
  my $template  = $self->_fav_template;
  my $prehtml   = '';

  for (0..$self->SPECIES_DISPLAY_LIMIT-1) {
    $prehtml .= $template =~ s/\{\{species\.(\w+)}\}/my $replacement = $species->[$_]{$1};/gre if $species->[$_] && $species->[$_]->{'favourite'};
  }

  ## Needed for autocomplete
  my $strains = [];
  foreach my $sp (@$species) {
    if ($sp->{'strainspage'}) {
      push @$strains, {
                      'homepage'  => $sp->{'strainspage'},
                      'name'      => $sp->{'name'},,
                      'common'    => (sprintf '%s %s', $sp->{'common'}, $sp->{'strain_type'}),
                      };
    }
  }

  my @ok_species = $sd->valid_species;
  my $sitename  = $self->hub->species_defs->ENSEMBL_SITETYPE;
  if (scalar @ok_species > 1) {
    my $list_html = sprintf qq(<h3>All genomes</h3>
      %s
      <h3 class="space-above"></h3>
      %s
      <p><a href="%s">View full list of all species</a></p>
      ), 
      $self->add_species_dropdown,
      $self->add_genome_groups, 
      $self->species_list_url; 

    my $sort_html = qq(<p>For easy access to commonly used genomes, drag from the bottom list to the top one</p>
        <p><strong>Favourites</strong></p>
          <ul class="_favourites"></ul>
        <p><a href="#Done" class="button _list_done">Done</a>
          <a href="#Reset" class="button _list_reset">Restore default list</a></p>
        <p><strong>Other available species</strong></p>
          <ul class="_species"></ul>
          );

  
    my %taxon_labels = $sd->multiX('TAXON_LABEL'); 
    unless (keys %taxon_labels) {
      %taxon_labels = %{$sd->TAXON_LABEL||{}};
    }

    return $self->dom->create_element('div', {
      'class'       => 'column_wrapper',
      'children'    => [{
              'node_name'   => 'div',
              'class'       => 'column-two static_all_species',
              'inner_HTML'  => $list_html,
            }, {
              'node_name'   => 'div',
              'class'       => 'column-two fave-genomes',
              'children'    => [{
                        'node_name'   => 'h3',
                        'inner_HTML'  => "Favourite genomes",
                      }, {
                        'node_name'   => 'div',
                        'class'       => [qw(_species_sort_container reorder_species clear hidden)],
                        'inner_HTML'  => $sort_html
                      }, {
                        'node_name'   => 'div',
                        'class'       => [qw(_species_fav_container species-list)],
                        'inner_HTML'  => $prehtml
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param',
                        'name'        => 'fav_template',
                        'value'       => encode_entities($template)
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param',
                        'name'        => 'list_template',
                        'value'       => encode_entities($self->_list_template)
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param json',
                        'name'        => 'species_list',
                        'value'       => encode_entities(to_json($species))
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param json',
                        'name'        => 'strains_list',
                        'value'       => encode_entities(to_json($strains))
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param',
                        'name'        => 'ajax_refresh_url',
                        'value'       => encode_entities($self->ajax_url)
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param',
                        'name'        => 'ajax_save_url',
                        'value'       => encode_entities($hub->url({qw(type Account action Favourites function Save)}))
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param',
                        'name'        => 'display_limit',
                        'value'       => SPECIES_DISPLAY_LIMIT
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param json',
                        'name'        => 'taxon_labels',
                        'value'       => encode_entities(to_json(\%taxon_labels))
                      }, {
                        'node_name'   => 'inputhidden',
                        'class'       => 'js_param json',
                        'name'        => 'taxon_order',
                        'value'       => encode_entities(to_json($sd->TAXON_ORDER))
                      }]
          }]
    });
  }
  else {
    my $species       = $ok_species[0];
    my $info          = $hub->get_species_info($species);
    my $homepage      = $hub->url({'species' => $species, 'type' => 'Info', 'function' => 'Index', '__clear' => 1});
    my $img_url       = $sd->img_url || '';
    my $sp_info = {
      homepage    => $homepage,
      name        => $info->{'name'},
      img         => sprintf('%sspecies/%s.png', $img_url, $info->{'image'}),
      common      => $info->{'common'},
      assembly    => $info->{'assembly'},
    };
    my $species_html = $template =~ s/\{\{species\.(\w+)}\}/my $replacement = $sp_info->{$1};/gre;
    return $self->dom->create_element('div', {
      'class'       => 'column_wrapper',
      'children'    => [{
                        'node_name'   => 'div',
                        'class'       => 'column-two fave-genomes',
                        'children'    => [{
                                          'node_name'   => 'h3',
                                          'inner_HTML'  => 'Available genomes'
                                          }, {
                                          'node_name'   => 'div',
                                          'inner_HTML'  => $species_html
                                        }]
                        }]
    });
  }
}


1;
