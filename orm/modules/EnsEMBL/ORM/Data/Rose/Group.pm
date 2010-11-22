package EnsEMBL::ORM::Data::Rose::Group;

### NAME: EnsEMBL::ORM::Data::Rose::Group;
### Wrapper for one or more EnsEMBL::ORM::Rose::Object::Group objects

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::Manager::Group;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_primary_keys {
  my $self = shift;
  $self->{'_primary_keys'} = [qw(webgroup_id)];
}

#TODO data mining methods

1;