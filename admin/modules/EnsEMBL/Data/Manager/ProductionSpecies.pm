package EnsEMBL::Data::Manager::ProductionSpecies;

### NAME: EnsEMBL::Data::Manager::ProductionSpecies
### Module to handle multiple ProductionSpecies entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple E::D::ProductionSpecies objects

use strict;
use warnings;

use base qw(EnsEMBL::Data::Manager);

sub object_class { 'EnsEMBL::Data::ProductionSpecies' }

## Auto-generate query methods: get_species, count_species, etc
__PACKAGE__->make_manager_methods('species');

sub get_lookup {
  my $lookup = [];
  my $current = get_species(
    'query'   => ['is_current' => 1],
    'sort_by' => 'web_name',
  );
  foreach my $species (@$current) {
    push @$lookup, {'name' => $species->web_name, 'value' => $species->species_id}
  }
  return $lookup;
}

1;
