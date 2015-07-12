=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::ComparaOrthologs;

use strict;

sub _species_sets {
## Group species into sets - separate method so it can be pluggable easily
  my ($self, $orthologue_list, $skipped) = @_;
  my $species_defs  = $self->hub->species_defs;

  my $set_order = [qw(primates rodents laurasia placental sauria fish all)];
  my %orthologue_map = qw(SEED BRH PIP RHS);

  my $species_sets = {
    'primates'  =>  {'title' => 'Primates', 'desc' => 'Humans and other primates', 'species' => []},
    'rodents'   =>  {'title' => 'Rodents',  'desc' => 'Rodents, rabbits and related species', 'species' => []},
    'laurasia'  =>  {'title' => 'Laurasiatheria', 'desc' => 'Carnivores, ungulates and insectivores',  'species' => []},
    'placental' =>  {'title' => 'Placental Mammals', 'desc' => 'All placental mammals', 'species' => []},
    'sauria'    =>  {'title' => 'Sauropsida', 'desc' => 'Birds and Reptiles', 'species' => []},
    'fish'      =>  {'title' => 'Fish', 'desc' => 'Ray-finned fishes', 'species' => []},
    'all'       =>  {'title' => 'All', 'desc' => 'All species, including invertebrates', 'species' => []},
  };

  # In addition to the following associations, the species are
  # automatically added to the 'all' category
  # The taxon names must be in sync with TAXON_ORDER
  # Currently missing: Mammalia Amphibia Vertebrata Chordata Eukaryota
  my $species_group_2_species_set = {
      Primates          => ['primates', 'placental'],
      Glires            => ['rodents', 'placental'],
      Laurasiatheria    => ['laurasia', 'placental'],
      Afrotheria        => ['placental'],
      Xenarthra         => ['placental'],
      Sauropsida        => ['sauria'],
      Actinopterygii    => ['fish'],
  };

  my $sets_by_species = {};

  my ($ortho_type);

  foreach my $species ($species_defs->valid_species) {
    next if $skipped->{$species};
    my $group = $species_defs->get_config($species, 'SPECIES_GROUP');
    push @{$species_sets->{'all'}{'species'}}, $species;
    my $sets = [];
    my $orthologues = $orthologue_list->{$species} || {};
    my $no_ortho = 0;
    if (!$orthologue_list->{$species} && $species ne $self->hub->species) {
      $no_ortho = 1;
    }

    foreach my $stable_id (keys %$orthologues) {
      my $orth_info = $orthologue_list->{$species}{$stable_id};
      my $orth_desc = ucfirst($orthologue_map{$orth_info->{'homology_desc'}} || $orth_info->{'homology_desc'});
      $ortho_type->{$species}{$orth_desc} = 1;
    }

    if ($species ne $self->hub->species && !$ortho_type->{$species}{'1-to-1'} && !$ortho_type->{$species}{'1-to-many'}
          && !$ortho_type->{$species}{'Many-to-many'}) {
      $no_ortho = 1;
    }  

    foreach my $ss_name (('all', @{$species_group_2_species_set->{$group}})) {
      push @{$species_sets->{$ss_name}{'species'}}, $species;
      push @$sets, $ss_name;
      while (my ($k, $v) = each (%{$ortho_type->{$species}})) {
        $species_sets->{$ss_name}{$k} += $v;
      }
      $species_sets->{$ss_name}{'none'}++ if $no_ortho;
      $species_sets->{$ss_name}{'all'}++ if $species ne $self->hub->species;
    }
    $sets_by_species->{$species} = $sets;
  }

  return ($species_sets, $sets_by_species, $set_order);
}

1;
