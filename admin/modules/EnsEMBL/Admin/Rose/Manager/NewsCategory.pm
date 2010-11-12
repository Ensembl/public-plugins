package EnsEMBL::Admin::Rose::Manager::NewsCategory;

### NAME: EnsEMBL::Admin::Rose::Manager::NewsCategory
### Module to handle multiple NewsCategory objects 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::NewsCategory objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::Admin::Rose::Object::NewsCategory' }

## Auto-generate query methods: get_categories, count_categories, etc
__PACKAGE__->make_manager_methods('categories');

sub get_lookup {
  my $lookup = [];
  my $cats = get_categories(
    'sort_by' => 'name',
  );
  foreach my $cat (@$cats) {
    push @$lookup, {'name' => $cat->name, 'value' => $cat->news_category_id}
  }
  return $lookup;
}


1;
