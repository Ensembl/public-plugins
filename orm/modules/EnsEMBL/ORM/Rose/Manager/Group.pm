package EnsEMBL::ORM::Rose::Manager::Group;

### NAME: EnsEMBL::ORM::Rose::Manager::Group
### Module to handle multiple Group entries 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Group objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Group' }

## Auto-generate query methods: get_groups, count_groups, etc
__PACKAGE__->make_manager_methods('groups');


sub fetch_with_members {
  ## Fetchs group(s) with given id(s) along with it's members
  ## @param Group id OR ArrayRef of group ids if multiple groups
  ## @param Flag if on, will return the active only users
  ## @return Rose::Object drived object, or arrayref of same if arrayref of ids provided as argument
  my ($self, $ids, $active_only) = @_;
  
  return unless $ids;
  
  my $method          = ref $ids eq 'ARRAY' ? 'fetch_by_primary_keys' : 'fetch_by_primary_key';
  my $params          = {'with_objects' => ['membership', 'membership.user'], 'sort_by' => 'user.name'};
  $params->{'query'}  = ['membership.member_status', 'active'] if $active_only;

  return $self->$method($ids, $params);
}

1;