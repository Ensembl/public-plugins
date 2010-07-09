package EnsEMBL::ORM::Rose::Manager::Release;

### NAME: EnsEMBL::ORM::Rose::Manager::Release
### Module to handle multiple Release entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Release objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Release' }

## Auto-generate query methods: get_releases, count_releases, etc
__PACKAGE__->make_manager_methods('releases');

sub get_lookup {
  my ($class, $hub) = @_;
  my $lookup = [];
  my $current = get_releases();
  foreach my $release (@$current) {
    push @$lookup, {'name' => $release->date, 'value' => $release->release_id}
  }
  return $lookup;
}

1;
