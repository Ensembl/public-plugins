package EnsEMBL::ORM::Rose::Manager::AnalysisDescription;

### NAME: EnsEMBL::ORM::Rose::Manager::AnalysisDescription
### Module to handle multiple AnalysisDescription entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::AnalysisDescription objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::AnalysisDescription;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::AnalysisDescription' }

1;