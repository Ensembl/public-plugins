package EnsEMBL::ORM::Rose::DbConnection;

### NAME: EnsEMBL::ORM::Rose::DbConnection
### Subclass of Rose::DB, a wrapper around DBI 

### STATUS: Under Development

### DESCRIPTION:
### This module defines the database connections available to EnsEMBL::Rose
### objects, by pulling them in from SpeciesDefs.pm

## TODO - get ensembl_production settings from SpeciesDefs (currently hard-coded)

use strict;
use warnings;

no warnings qw(uninitialized);

use EnsEMBL::Web::SpeciesDefs;
use base qw(Rose::DB);

our $species_defs = EnsEMBL::Web::SpeciesDefs->new;

## All connections currently use the same user with write permissions
our $db_user = $species_defs->multidb->{'DATABASE_WEBSITE'}{'USER'}
                  || $species_defs->DATABASE_WRITE_USER;

our $db_pass = defined $species_defs->multidb->{'DATABASE_WEBSITE'}{'PASS'}
                  ? $species_defs->multidb->{'DATABASE_WEBSITE'}{'PASS'}
                  : $species_defs->DATABASE_WRITE_PASS;


## Use a private registry for this class
__PACKAGE__->use_private_registry;

## Set the default domain
__PACKAGE__->default_domain('ensembl');

__PACKAGE__->default_type('ticket');

## Register data sources
__PACKAGE__->register_db(
  type      => 'website',
  driver    => 'mysql',
  database  => $species_defs->multidb->{'DATABASE_WEBSITE'}{'NAME'},
  host      => $species_defs->multidb->{'DATABASE_WEBSITE'}{'HOST'},
  port      => $species_defs->multidb->{'DATABASE_WEBSITE'}{'PORT'},
  username  => $species_defs->multidb->{'DATABASE_WEBSITE'}{'USER'} || $db_user,
  password  => $species_defs->multidb->{'DATABASE_WEBSITE'}{'PASS'} || $db_pass,
);

__PACKAGE__->register_db(
  type      => 'user',
  driver    => 'mysql',
  database  => $species_defs->ENSEMBL_USERDB_NAME,
  host      => $species_defs->ENSEMBL_USERDB_HOST,
  port      => $species_defs->ENSEMBL_USERDB_PORT,
  username  => $species_defs->ENSEMBL_USERDB_USER || $db_user,
  password  => $species_defs->ENSEMBL_USERDB_PASS || $db_pass,
);

__PACKAGE__->register_db(
  type      => 'production',
  driver    => 'mysql',
  database  => $species_defs->multidb->{'DATABASE_PRODUCTION'}{'NAME'},
  host      => $species_defs->multidb->{'DATABASE_PRODUCTION'}{'HOST'},
  port      => $species_defs->multidb->{'DATABASE_PRODUCTION'}{'PORT'},
  username  => $species_defs->multidb->{'DATABASE_PRODUCTION'}{'USER'} || $db_user,
  password  => $species_defs->multidb->{'DATABASE_PRODUCTION'}{'PASS'} || $db_pass,
);

__PACKAGE__->register_db(
  type      => 'healthcheck',
  driver    => 'mysql',
  database  => $species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'NAME'},
  host      => $species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'HOST'},
  port      => $species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'PORT'},
  username  => $species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'USER'} || $db_user,
  password  => $species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'PASS'} || $db_pass,
);

__PACKAGE__->register_db(
  type      => 'ticket',
  domain    => 'ensembl',
  driver    => 'mysql',
  database  => $species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'},
  host      => $species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
  port      => $species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
  username  => $db_user,
  password  => $db_pass,
);

1;

