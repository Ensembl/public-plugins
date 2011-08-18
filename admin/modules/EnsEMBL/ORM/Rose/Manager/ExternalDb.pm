package EnsEMBL::ORM::Rose::Manager::ExternalDb;

### NAME: EnsEMBL::ORM::Rose::Manager::ExternalDb
### Module to handle multiple ExternalDb entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::ExternalDb objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::ExternalDb;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::ExternalDb' }

1;