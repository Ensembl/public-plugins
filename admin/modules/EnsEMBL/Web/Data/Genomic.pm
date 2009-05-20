package EnsEMBL::Web::Data::Genomic;

use strict;
use warnings;

use base qw/EnsEMBL::Web::Data/;
use DBI;
use Data::Dumper;

my %dbh;
my $current_dbh;

##
## EnsEMBL::Web::Data::Analysis::connect($db_info) - dynamic db connection
##
sub connect {
    my $self    = shift;
    my $species = shift || __PACKAGE__->species_defs->ENSEMBL_PRIMARY_SPECIES;
    my $db      = shift || 'DATABASE_CORE';
    my $db_info =  __PACKAGE__->species_defs->get_config($species, 'databases');

    my $dsn = join(':',
      'dbi',
      'mysql',
      $db_info->{$db}{'NAME'},
      $db_info->{$db}{'HOST'},
      $db_info->{$db}{'PORT'},
    );

    if ($dbh{$dsn}) {
        $self->{__current_dbh} = $dbh{$dsn};
    } else {
        warn "DSN $dsn";
        $self->{__current_dbh} = $dbh{$dsn} = DBI->connect_cached(
            $dsn,
            __PACKAGE__->species_defs->DATABASE_WRITE_USER,
            __PACKAGE__->species_defs->DATABASE_WRITE_PASS,
            {
              RaiseError => 1,
              PrintError => 1,
              AutoCommit => 1,
            }
        );
        warn "CONNECTED: ".Dumper($dbh{$dsn});
        if (not $self->{__current_dbh}) {
            warn "Could not connect to '$dsn' $DBI::errstr";
            return 0;
        }
    }
    
    $current_dbh = $self->{__current_dbh};
    return 1;
}
 
sub db_Main {
    my $self = shift;
    
    if (ref $self) {
      return $self->{__current_dbh};
    } else {
      return $current_dbh;
    }
}

1;
