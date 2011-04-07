package EnsEMBL::ORM::Rose::Manager::MetaKey;

### NAME: EnsEMBL::ORM::Rose::Manager::MetaKey
### Module to handle multiple MetaKey entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::MetaKey objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::MetaKey' }

__PACKAGE__->make_manager_methods('meta_key'); ## Auto-generate query methods: get_meta_key, count_meta_key, etc

1;