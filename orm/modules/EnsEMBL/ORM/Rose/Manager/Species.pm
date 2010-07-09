package EnsEMBL::ORM::Rose::Manager::Species;

### NAME: EnsEMBL::ORM::Rose::Manager::Species
### Module to handle multiple Species entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Species objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Species' }

## Auto-generate query methods: get_species, count_species, etc
__PACKAGE__->make_manager_methods('species');

sub get_lookup {
  my $lookup = [];
  my $current = get_species(
    'query'   => [],
    'sort_by' => 'common_name',
  );
  foreach my $species (@$current) {
    push @$lookup, {'name' => $species->common_name, 'value' => $species->species_id}
  }
  return $lookup;
}

1;
