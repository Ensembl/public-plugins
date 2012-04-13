package EnsEMBL::ORM::Rose::Manager::Login;

### NAME: EnsEMBL::ORM::Rose::Manager::Login

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

use EnsEMBL::ORM::Rose::Object::Login;

sub object_class { 'EnsEMBL::ORM::Rose::Object::Login' }

sub get_by_identity {
  ## Gets a Login object for given identity column value, can be an openid url or email for local accounts
  my ($self, $identity) = @_;

  return shift @{$self->get_objects(
    'query'         => ['identity', $identity],
    'with_objects'  => ['user'],
    'limit'         => 1
  )};
}

1;