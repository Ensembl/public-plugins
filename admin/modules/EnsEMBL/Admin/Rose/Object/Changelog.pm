package EnsEMBL::Admin::Rose::Object::Changelog;

### NAME: EnsEMBL::Admin::Rose::Object::Changelog
### ORM class for the changelog table in ensembl_production 

### STATUS: Stable

use strict;
use warnings;
use base qw(EnsEMBL::ORM::Rose::Object);

## Define schema
__PACKAGE__->meta->setup(
  table       => 'changelog',

  columns     => [
    changelog_id      => {type => 'serial', primary_key => 1, not_null => 1}, 
    release_id        => {type => 'integer'},
    title             => {type => 'varchar'},
    content           => {type => 'text'},
    notes             => {type => 'text'},
    status            => {type => 'enum', 'values' => [qw(declared handed_over postponed cancelled)]},
    team              => {type => 'enum', 'values' => [qw(Compara Core Funcgen EnsemblGenomes Genebuild Mart Outreach Variation Web Wormbase)]},
    assembly          => {type => 'enum', 'values' => [qw(N Y)]},
    gene_set          => {type => 'enum', 'values' => [qw(N Y)]},
    repeat_masking    => {type => 'enum', 'values' => [qw(N Y)]},
    stable_id_mapping => {type => 'enum', 'values' => [qw(N Y)]},
    affy_mapping      => {type => 'enum', 'values' => [qw(N Y)]},
    biomart_affected  => {type => 'enum', 'values' => [qw(N Y)]},
    db_status         => {type => 'enum', 'values' => [qw(N/A unchanged patched new)]},
    created_by        => {type => 'integer'},
    created_at        => {type => 'datetime'},
    modified_by       => {type => 'integer'},
    modified_at       => {type => 'datetime'},
  ],

  relationships => [
    species => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::Admin::Rose::Object::ChangelogSpecies',
    },
  ],

);

sub init_db {
  ### Set up the db connection 
  EnsEMBL::ORM::Rose::DbConnection->new('production'); 
}

1;
