package EnsEMBL::Admin::Rose::Manager::Changelog;

### NAME: EnsEMBL::Admin::Rose::Manager::Changelog
### Module to handle multiple Changelog entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Changelog objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::Admin::Rose::Object::Changelog' }

## Auto-generate query methods: get_changelogs, count_changelogs, etc
__PACKAGE__->make_manager_methods('changelogs');



1;
