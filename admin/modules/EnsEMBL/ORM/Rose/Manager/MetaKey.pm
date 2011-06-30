package EnsEMBL::ORM::Rose::Manager::MetaKey;

### NAME: EnsEMBL::ORM::Rose::Manager::MetaKey
### Module to handle multiple MetaKey entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::MetaKey objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::MetaKey;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::MetaKey' }

1;