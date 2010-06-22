package EnsEMBL::Data;

### NAME: EnsEMBL::Data
### Base class for a Rose::DB::Object object 

### STATUS: Under Development
### You will need to uncomment the use base line in order to test this code!

### DESCRIPTION:
### This module and its children provide access to non-genomic
### databases, using the Rose::DB suite of ORM modules

### At the moment this base class doesn't really do anything apart from
### inheritance, but it avoids having to comment out the use lines
### on multiple modules when running on pre-Lenny boxes...

use strict;
use warnings;

no warnings qw(uninitialized);

use EnsEMBL::Data::DBSQL::RoseDB;

use base qw(Rose::DB::Object);

1;

