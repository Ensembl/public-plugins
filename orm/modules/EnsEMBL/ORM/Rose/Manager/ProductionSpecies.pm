package EnsEMBL::ORM::Rose::Manager::ProductionSpecies;

### NAME: EnsEMBL::ORM::Rose::Manager::ProductionSpecies
### Module to handle multiple ProductionSpecies entries 

### N.B. Not to be confused with Ensembl::ORM::Rose::Manager::Species - 
### this module's name is intended to distinguish it from 
### ensembl_website.species, which has a different schema and
### different table relationships

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::ProductionSpecies objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::ProductionSpecies' }

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
