package EnsEMBL::ORM::Rose::Manager::UserRecord;

### NAME: EnsEMBL::ORM::Rose::Manager::UserRecord
### Module to handle multiple Group entries 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Group objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::UserRecord;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::UserRecord' }

1;