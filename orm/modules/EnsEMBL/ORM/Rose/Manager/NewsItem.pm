package EnsEMBL::ORM::Rose::Manager::NewsItem;

### NAME: EnsEMBL::ORM::Rose::Manager::NewsItem
### Module to handle multiple NewsItems 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::NewsItem objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::NewsItem' }

## Auto-generate query methods: get_newsitems, count_newsitems, etc
__PACKAGE__->make_manager_methods('newsitems');

1;
