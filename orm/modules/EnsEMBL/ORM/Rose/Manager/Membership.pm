package EnsEMBL::ORM::Rose::Manager::Membership;

### NAME: EnsEMBL::ORM::Rose::Manager::Membership
### Module to handle multiple Membership entries 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Membership objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Membership' }

## Auto-generate query methods: get_memberships, count_memberships, etc
__PACKAGE__->make_manager_methods('memberships');

1;
