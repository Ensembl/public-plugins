package EnsEMBL::ORM::Rose::Object;

### NAME: EnsEMBL::Rose::ORM::Object
### Base class for a Rose::DB::Object object 

### STATUS: Under Development

### DESCRIPTION:
### This module and its children provide access to non-genomic
### databases, using the Rose::DB suite of ORM modules

use strict;
use warnings;

no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::DbConnection;

use base qw(Rose::DB::Object);


## Tip: When debugging, change the value below from return to carp/cluck/confess/croak,
## to get the corresponding Carp behaviour in your data objects

__PACKAGE__->meta->error_mode('return');

1;

