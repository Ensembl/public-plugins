package EnsEMBL::ORM::Rose::Manager::Record;

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::Record;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Record' }

1;