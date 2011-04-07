package EnsEMBL::ORM::Rose::Manager::WebData;

### NAME: EnsEMBL::ORM::Rose::Manager::WebData
### Module to handle multiple WebData entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::WebData objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::WebData' }

__PACKAGE__->make_manager_methods('web_data'); ## Auto-generate query methods: get_web_data, count_web_data, etc

1;