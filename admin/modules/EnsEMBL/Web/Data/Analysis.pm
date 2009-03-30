package EnsEMBL::Web::Data::Analysis;

use strict;
use warnings;

use base qw/EnsEMBL::Web::Data/;
use EnsEMBL::Web::DBSQL::CoreDBConnection (__PACKAGE__->species_defs);

__PACKAGE__->table('analysis');
__PACKAGE__->set_primary_key('analysis_id');

__PACKAGE__->add_queriable_fields(
    created         => 'datetime',
    logic_name      => 'varchar(128)',
    db              => 'varchar(120)',
    db_version      => 'varchar(40)',
    db_file         => 'varchar(120)',
    program         => 'varchar(80)',
    program_version => 'varchar(40)',
    program_file    => 'varchar(80)',
    parameters      => 'text',
    module          => 'varchar(80)',
    module_version  => 'varchar(40)',
    gff_source      => 'varchar(40)',
    gff_feature     => 'varchar(40)',
);

__PACKAGE__->might_have(analysis_description => 'EnsEMBL::Web::Data::AnalysisDescription, qw/display_label description/');

########################################################################
## Several tweaks to make multiple database connections
########################################################################

use DBI;

my %dbh;
my $current_dbh;

##
## EnsEMBL::Web::Data::Analysis::connect($db_info) - dynamic db connection
## $db_info = {NAME => 'dbname', HOST => ..., PORT => ...}
##
sub connect {
    my $db_info = shift;

    my $dsn = join(':',
      'dbi',
      'mysql',
      $db_info->{'NAME'},
      $db_info->{'HOST'},
      $db_info->{'PORT'},
    );

    if ($dbh{$dsn}) {
        $current_dbh = $dbh{$dsn};
    } else {
        $current_dbh = $dbh{$dsn} = DBI->connect_cached(
            $dsn,
            __PACKAGE__->species_defs->DATABASE_WRITE_USER,
            __PACKAGE__->species_defs->DATABASE_WRITE_PASS,
            {
              RaiseError => 1,
              PrintError => 1,
              AutoCommit => 1,
            }
        );
        if (not $current_dbh) {
            warn "Could not connect to '$dsn' $DBI::errstr";
            return 0;
        }
    }
    return 1;
}
 
sub db_Main {
    my $self = shift;
    return $current_dbh;
}

1;
