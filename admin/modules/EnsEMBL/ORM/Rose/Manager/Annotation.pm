package EnsEMBL::ORM::Rose::Manager::Annotation;

### NAME: EnsEMBL::ORM::Rose::Manager::Annotation
### Module to handle multiple Annotation entries 

### STATUS: Stable 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Annotation objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Annotation;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Annotation' }

1;