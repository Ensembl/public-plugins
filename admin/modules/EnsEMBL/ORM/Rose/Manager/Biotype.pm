package EnsEMBL::ORM::Rose::Manager::Biotype;

### NAME: EnsEMBL::ORM::Rose::Manager::Biotype
### Module to handle multiple Biotype entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Biotype objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Biotype;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Biotype' }

1;