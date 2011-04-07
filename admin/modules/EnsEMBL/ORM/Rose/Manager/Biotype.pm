package EnsEMBL::ORM::Rose::Manager::Biotype;

### NAME: EnsEMBL::ORM::Rose::Manager::Biotype
### Module to handle multiple Biotype entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Biotype objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Biotype' }

__PACKAGE__->make_manager_methods('biotype'); ## Auto-generate query methods: get_biotype, count_biotype, etc

1;