package EnsEMBL::Admin::Rose::Object::Help;

### NAME: EnsEMBL::Admin::Rose::Object::Help
### ORM class for the help_record table in ensembl_website

### STATUS: Stable

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'report',

  columns     => [
    help_record_id  => {type => 'serial', primary_key => 1, not_null => 1}, 
    type            => {type => 'varchar', 'length' => '255'},
    keyword         => {type => 'varchar', 'length' => '255'},
    data            => {type => 'text'},
    status          => {type => 'enum', 'values' => [qw(draft live dead)]},
    helpful         => {type => 'integer'},
    not_helpful     => {type => 'integer'},
  ],
);

sub init_db {
  ### Set up the db connection 
  EnsEMBL::ORM::Rose::DbConnection->new('website'); 
}

1;
