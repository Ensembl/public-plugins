package EnsEMBL::ORM::Rose::Manager::AnalysisWebData;

### NAME: EnsEMBL::ORM::Rose::Manager::AnalysisWebData
### Module to handle multiple AnalysisWebData entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::AnalysisWebData objects

use strict;
use warnings;

use EnsEMBL::ORM::Rose::Object::AnalysisWebData;

use base qw(EnsEMBL::ORM::Rose::Manager::Trackable);

sub object_class { 'EnsEMBL::ORM::Rose::Object::AnalysisWebData' }

1;