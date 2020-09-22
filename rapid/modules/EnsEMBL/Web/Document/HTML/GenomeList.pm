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

sub get_edit_icon_markup { return ''; }

sub get_list_html {

  my ($self) = @_;
  
  sprintf qq(<h3>All genomes</h3>
      %s
      <h3 class="space-above"></h3>
      %s
      <p><a href="%s">View and download available data for all species</a></p>
      ), 
      $self->add_species_dropdown,
      $self->add_genome_groups, 
      $self->species_list_url; 

}

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

  for (@fav, sort {$species->{$a}{'display_name'} cmp $species->{$b}{'display_name'}} keys %$species) {

    next if ($done{$_} || !$species->{$_});
    $done{$_} = 1;

    my $homepage      = $hub->url({'species' => $_, 'type' => 'Info', 'function' => 'Index', '__clear' => 1});

    push @list, { 
      key         => $_,
      group       => $species->{$_}{'group'},
      homepage    => $homepage,
      name        => $species->{$_}{'name'},
      img         => sprintf('%sspecies/%s.png', $img_url, $species->{$_}{'image'}),
      common      => $species->{$_}{'display_name'},
      assembly    => $species->{$_}{'assembly'},
      assembly_v  => $species->{$_}{'assembly_version'},
      favourite   => $fav{$_} ? 1 : 0,
      strainspage => '',
      strain_type => '', 
      has_alt     => 0,
      extra       => '',
    };

  }

  return \@list;
}


1;
