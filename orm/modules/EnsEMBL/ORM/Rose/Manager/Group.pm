package EnsEMBL::ORM::Rose::Manager::Group;

### NAME: EnsEMBL::ORM::Rose::Manager::Group
### Module to handle multiple Group entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Group objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Group' }

## Auto-generate query methods: get_groups, count_groups, etc
__PACKAGE__->make_manager_methods('groups');

1;
