=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

sub species_set_config {
  my $self = shift;

  my $set_order = [qw(primates rodents laurasia placental sauria fish all)];
  my $species_sets = {
    'primates'  =>  {'title' => 'Primates', 'desc' => 'Humans and other primates', 'species' => []},
    'rodents'   =>  {'title' => 'Rodents and related species',  'desc' => 'Rodents, lagomorphs and tree shrews', 'species' => []},
    'laurasia'  =>  {'title' => 'Laurasiatheria', 'desc' => 'Carnivores, ungulates and insectivores',  'species' => []},
    'placental' =>  {'title' => 'Placental Mammals', 'desc' => 'All placental mammals', 'species' => []},
    'sauria'    =>  {'title' => 'Sauropsida', 'desc' => 'Birds and Reptiles', 'species' => []},
    'fish'      =>  {'title' => 'Fish', 'desc' => 'Ray-finned fishes', 'species' => []},
    'all'       =>  {'title' => 'All', 'desc' => 'All species, including invertebrates', 'species' => []},
  };
  return ($set_order, $species_sets);
}

1;
