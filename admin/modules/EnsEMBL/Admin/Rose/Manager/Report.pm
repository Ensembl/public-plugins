package EnsEMBL::Admin::Rose::Manager::Report;

### NAME: EnsEMBL::Admin::Rose::Manager::Report
### Module to handle multiple Report entries 

### STATUS: Stable 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Report objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::Admin::Rose::Object::Report' }

## Auto-generate query methods: get_reports, count_reports, etc
__PACKAGE__->make_manager_methods('reports');



1;
