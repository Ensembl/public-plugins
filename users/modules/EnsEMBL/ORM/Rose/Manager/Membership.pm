package EnsEMBL::ORM::Rose::Manager::Membership;

### NAME: EnsEMBL::ORM::Rose::Manager::Membership
### Module to handle multiple Membership entries 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Membership objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Membership;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Membership' }

1;