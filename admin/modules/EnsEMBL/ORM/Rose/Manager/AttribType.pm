package EnsEMBL::ORM::Rose::Manager::AttribType;

### NAME: EnsEMBL::ORM::Rose::Manager::AttribType
### Module to handle multiple AttribType entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::AttribType objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::AttribType;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::AttribType' }

1;