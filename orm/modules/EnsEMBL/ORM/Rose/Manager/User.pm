package EnsEMBL::ORM::Rose::Manager::User;

### NAME: EnsEMBL::ORM::Rose::Manager::User
### Module to handle multiple User entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::User objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::User' }

## Auto-generate query methods: get_users, count_users, etc
__PACKAGE__->make_manager_methods('users');

1;
