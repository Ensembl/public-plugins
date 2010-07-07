package EnsEMBL::ORM::Rose::Manager::News;

### NAME: EnsEMBL::ORM::Rose::Manager::News
### Module to handle multiple NewsItems 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple E::D::NewsItem objects
### Note that we do not need a separate manager for NewsCategory,
### because it is just a lookup table that we have no need to query
### directly

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::NewsItem' }

## Auto-generate query methods: get_newsitems, count_newsitems, etc
__PACKAGE__->make_manager_methods('newsitems');



1;
