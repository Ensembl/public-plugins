package EnsEMBL::ORM::Rose::Manager::WebData;

### NAME: EnsEMBL::ORM::Rose::Manager::WebData
### Module to handle multiple WebData entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::WebData objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::WebData;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::WebData' }

1;