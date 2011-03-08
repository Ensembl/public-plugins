package EnsEMBL::ORM::Rose::Manager::Species;

### NAME: EnsEMBL::ORM::Rose::Manager::Species
### Module to handle multiple Species entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Species objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Species' }

__PACKAGE__->make_manager_methods('species'); ## Auto-generate query methods: get_species, count_species, etc

1;