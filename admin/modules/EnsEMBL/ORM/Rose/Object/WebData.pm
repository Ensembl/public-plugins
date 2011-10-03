package EnsEMBL::ORM::Rose::Object::WebData;

### NAME: EnsEMBL::ORM::Rose::Object::WebData
### ORM class for the biotype table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant {
  ROSE_DB_NAME  => 'production',  
};

## Define schema
__PACKAGE__->meta->setup(
  table           => 'web_data',

  columns         => [
    web_data_id => {type => 'serial', primary_key => 1, not_null => 1},
    data        => {type => 'datastructure' },
  ],
  title_column    => 'data',

  relationships   => [
    analysis_web_data => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::AnalysisWebData',
      'column_map'  => {'web_data_id' => 'web_data_id'}
    },
  ],
);


1;