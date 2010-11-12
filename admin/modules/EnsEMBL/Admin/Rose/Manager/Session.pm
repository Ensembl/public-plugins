package EnsEMBL::Admin::Rose::Manager::Session;

### NAME: EnsEMBL::Admin::Rose::Manager::Session
### Module to handle multiple Session entries 

### STATUS: Stable 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Session objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::Admin::Rose::Object::Session' }

## Auto-generate query methods: get_sessions, count_sessions, etc
__PACKAGE__->make_manager_methods('sessions');



1;
