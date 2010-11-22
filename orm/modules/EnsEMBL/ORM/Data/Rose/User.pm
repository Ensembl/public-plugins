package EnsEMBL::ORM::Data::Rose::User;

### NAME: EnsEMBL::ORM::Data::Rose::User;
### Wrapper for one or more EnsEMBL::ORM::Rose::Object::User objects

use strict;

use EnsEMBL::ORM::Rose::Manager::User;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_primary_keys {
  my $self = shift;
  $self->{'_primary_keys'} = [qw(user_id)];
}

#data mining methods
sub fetch_by_group {
  my ($self, $group_id) = @_;
  return undef unless $group_id;
  
  my $users = $self->manager_class->get_users(
    with_objects    => 'membership',
    query => [
      'membership.webgroup_id'    => $group_id,
    ],
    sort_by        => 'name',
  );
  $self->data_objects(@$users);
  return $users;
}

1;