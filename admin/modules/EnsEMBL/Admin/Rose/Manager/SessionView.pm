package EnsEMBL::Admin::Rose::Manager::SessionView;

### NAME: EnsEMBL::Admin::Rose::Manager::SessionView
### Module to handle multiple SessionView entries 

### STATUS: Stable 

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::SessionView objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);
use EnsEMBL::ORM::Rose::DbConnection;

sub object_class { 'EnsEMBL::Admin::Rose::Object::SessionView' }

## Auto-generate query methods: get_sessionviews, count_sessionviews, etc
__PACKAGE__->make_manager_methods('sessionviews');

sub max_for_release {
  my ($class, $release) = @_;

  ## We need to do this query manually, as RDBO doesn't support arbitrary SQL any other way
  my $sql = qq(
    SELECT
      MAX(session_id)
    FROM
      session_v
    WHERE
      end_time IS NOT NULL
      AND db_release = ?
  );

  my $max;

  eval {
    my $dbh = EnsEMBL::ORM::Rose::DbConnection->new->retain_dbh;
    local $dbh->{'RaiseError'} = 1;
    my $sth = $dbh->prepare($sql);
    $sth->execute($release);

    while(my $row = $sth->fetchrow_arrayref) {
      $max = $row->[0];
    }
    $dbh->disconnect;
  };

  return $max;
}


1;
