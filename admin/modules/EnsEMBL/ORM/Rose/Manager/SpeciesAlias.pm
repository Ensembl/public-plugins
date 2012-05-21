package EnsEMBL::ORM::Rose::Manager::SpeciesAlias;

### NAME: EnsEMBL::ORM::Rose::Manager::SpeciesAlias
### Module to handle multiple SpeciesAlias entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::SpeciesAlias objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::SpeciesAlias;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::SpeciesAlias' }

1;