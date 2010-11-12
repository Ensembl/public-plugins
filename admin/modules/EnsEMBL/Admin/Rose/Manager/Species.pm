package EnsEMBL::Admin::Rose::Manager::Species;

### NAME: EnsEMBL::Admin::Rose::Manager::Species
### Module to handle multiple Species entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Species objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::Admin::Rose::Object::Species' }

## Auto-generate query methods: get_species, count_species, etc
__PACKAGE__->make_manager_methods('species');

sub get_lookup {
### For interface lookups, we only need those species that are in 
### the current release
  my ($class, $hub) = @_;
  my $lookup = [];
  my $current = get_species(
    'with_objects'  => ['releases'],
  );
  foreach my $species (@$current) {
    push @$lookup, {'name' => $species->common_name, 'value' => $species->species_id}
  }
  return $lookup;
}

=pod
    'query'         => ['ens_release.release_id' => $hub->species_defs->ENSEMBL_VERSION],
    'sort_by'   => 'common_name',

=cut
1;
