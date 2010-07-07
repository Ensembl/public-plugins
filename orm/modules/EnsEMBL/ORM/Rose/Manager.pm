package EnsEMBL::ORM::Rose::Manager;

### NAME: EnsEMBL::ORM::Rose::Manager
### Base class for a Rose::DB::Object::Manager object 

### STATUS: Under Development
### (Doesn't do much at the moment!)

### DESCRIPTION:
### This module and its children provide access to non-genomic
### databases, using the Rose::DB suite of ORM modules

use strict;
use warnings;

no warnings qw(uninitialized);

use base qw(Rose::DB::Object::Manager);



1;

