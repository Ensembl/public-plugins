package EnsEMBL::ORM::Rose::Manager;

### NAME: EnsEMBL::ORM::Rose::Manager
### Sub-class of Rose::DB::Object::Manager, used to handle multiple 
### EnsEMBL::ORM::Rose::Object objects

### STATUS: Under Development

### DESCRIPTION:
### Children of this class auto-generate access methods for one or more
### domain objects, e.g. if the object's name is Thing, the manager can
### auto-generate methods 'get_things', 'get_things_count', and so on

use strict;
use warnings;

no warnings qw(uninitialized);

use base qw(Rose::DB::Object::Manager);

sub get_lookup {
  ### Called by EnsEMBL::ORM::Data::Rose to create "lookups" on the interface -
  ### returns the data structure (an array of hashrefs) used by the 'values' 
  ### parameter of an EnsEMBL::Web::Form::Element::DropDown
  ### As such, it only needs to be implemented in the managers of objects that 
  ### are at the other end of a one-to-many or many-to-many relationship with 
  ### the record being manipulated by a CRUD interface
}

1;

