package EnsEMBL::ORM::Rose::Manager::Membership;

### NAME: EnsEMBL::ORM::Rose::Manager::Membership
### Module to handle multiple Membership entries 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Membership objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Membership;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Membership' }

sub add_active_only_query {
  ## @overrides
  my ($self, $params) = @_;
  return $self->SUPER::add_active_only_query($params) if $params->{'object_class'} && $params->{'object_class'} ne $self->object_class;  #override only for Membership objects
  push @{$params->{'query'}},  qw(member_status active status active);
}

1;