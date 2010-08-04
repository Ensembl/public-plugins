package EnsEMBL::ORM::Data::Rose::User;

### NAME: EnsEMBL::ORM::Data::Rose::User;
### Wrapper for one or more EnsEMBL::ORM::Rose::Object::User objects

### DESCRIPTION:

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::Manager::User;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_primary_keys {
  my $self = shift;
  $self->{'_primary_keys'} = [qw(user_id)];
}

1;
