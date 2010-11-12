package EnsEMBL::Admin::Rose::Manager::Annotation;

### NAME: EnsEMBL::Admin::Rose::Manager::Annotation
### Module to handle multiple Annotation entries 

### STATUS: Stable 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Annotation objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::Admin::Rose::Object::Annotation' }

## Auto-generate query methods: get_annotations, count_annotations, etc
__PACKAGE__->make_manager_methods('annotations');



1;
