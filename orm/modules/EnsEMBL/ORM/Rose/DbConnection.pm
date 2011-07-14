package EnsEMBL::ORM::Rose::DbConnection;

### NAME: EnsEMBL::ORM::Rose::DbConnection
### Subclass of Rose::DB, a wrapper around DBI 

### DESCRIPTION:
### This module defines the database connections available to EnsEMBL::Rose objects

### DO NOT MODIFY THIS CLASS - to register more connections, add them to $SiteDefs::ROSE_DB_DATABASES
### ROSE_DB_DATABASES (Hashref) is used to list all the database connection
### key     - While using a connection for a Rose::Object drived object, if ROSE_DB_NAME constant in that object class matches with this key, then this connection is used for that object
### value   - value itself can be a hashref containg key - database, host, port, username and password OR can be a string pointing to connection datails saved in species def

use strict;
use warnings;

use EnsEMBL::Web::SpeciesDefs;

use base qw(Rose::DB);

my $species_defs = EnsEMBL::Web::SpeciesDefs->new;

## Use a private registry for this class
__PACKAGE__->use_private_registry;

## Set the default domain & type
__PACKAGE__->default_domain('ensembl');
__PACKAGE__->default_type('user');

## Register data source for users
__PACKAGE__->register_db(
  type      => 'user',
  driver    => 'mysql',
  database  => $species_defs->ENSEMBL_USERDB_NAME,
  host      => $species_defs->ENSEMBL_USERDB_HOST,
  port      => $species_defs->ENSEMBL_USERDB_PORT,
  username  => $species_defs->ENSEMBL_USERDB_USER || $species_defs->DATABASE_WRITE_USER,
  password  => $species_defs->ENSEMBL_USERDB_PASS || $species_defs->DATABASE_WRITE_PASS,
);

## Register other data sources from site defs
while (my ($key, $details) = each %{$SiteDefs::ROSE_DB_DATABASES}) {

  my $params = $details;
  if (!ref $params) {
    $params = $species_defs->multidb->{$details} or warn "Database connection properties for '$details' could not be found in Species Def" and next;
    $params = {
      'database'  => $params->{'NAME'},
      'host'      => $params->{'HOST'} || $species_defs->DATABASE_HOST,
      'port'      => $params->{'PORT'} || $species_defs->DATABASE_HOST_PORT,
      'username'  => $params->{'USER'} || $species_defs->DATABASE_WRITE_USER,
      'password'  => $params->{'PASS'} || $species_defs->DATABASE_WRITE_PASS,
    };
  }
  $params->{'driver'} ||= 'mysql';
  $params->{'type'}     = $key;

  __PACKAGE__->register_db(%$params);
}

1;