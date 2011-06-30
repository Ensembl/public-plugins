package EnsEMBL::ORM::Rose::Manager::Changelog;

### NAME: EnsEMBL::ORM::Rose::Manager::Changelog
### Module to handle multiple Changelog entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Changelog objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Changelog;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Changelog' }

1;