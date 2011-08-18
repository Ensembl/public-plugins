package EnsEMBL::ORM::Rose::Manager::Session;

### NAME: EnsEMBL::ORM::Rose::Manager::Session
### Module to handle multiple Session entries 

### STATUS: Stable 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Session objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Session;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Session' }

sub fetch_single {
  ## fetches first or last session from the db for the given release
  ## @param Release
  ## @param 'first' or 'last' (defaults to 'last')
  ## @return EnsEMBL::ORM::Rose::Object::Session object if found any
  my ($self, $release, $first_or_last) = @_;
  return undef unless $release;

  my $session = $self->get_objects(
    query   => [
      'db_release'  => $release,
#       '!start_time' => undef,
#       '!end_time'   => undef,
    ],
    sort_by => sprintf('session_id %s', ($first_or_last ||= '') eq 'first' ? 'ASC' : 'DESC'),
    limit   => 1
  );
  return @$session ? $session->[0] : undef;
}

1;
