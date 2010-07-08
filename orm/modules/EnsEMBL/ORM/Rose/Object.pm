package EnsEMBL::ORM::Rose::Object;

### NAME: EnsEMBL::Rose::ORM::Object
### Base class for a Rose-based domain object 

### STATUS: Under Development

### DESCRIPTION:
### This module and its children provide access to non-genomic
### databases, using the Rose::DB::Object suite of ORM modules

### Tip: When debugging, change the value of the error_mode (below) 
### from 'return' to 'carp'/'cluck'/'confess'/'croak' to produce
### the desired Carp behaviour in your data objects

use strict;
use warnings;

no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::DbConnection;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->error_mode('return');

1;

