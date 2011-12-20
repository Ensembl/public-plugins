package EnsEMBL::ORM::Rose::Manager::HelpRecord;

### NAME: EnsEMBL::ORM::Rose::Manager::HelpRecord
### Module to handle multiple HelpRecord entries 

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::HelpRecord;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::HelpRecord' }

1;