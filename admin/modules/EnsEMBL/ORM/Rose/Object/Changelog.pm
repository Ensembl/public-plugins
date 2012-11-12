package EnsEMBL::ORM::Rose::Object::Changelog;

### NAME: EnsEMBL::ORM::Rose::Object::Changelog
### ORM class for the changelog table in ensembl_production 

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'production';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'changelog',

  columns     => [
    changelog_id          => {type => 'serial', primary_key => 1, not_null => 1}, 
    release_id            => {type => 'integer'},
    title                 => {type => 'varchar'},
    content               => {type => 'text'},
    notes                 => {type => 'text'},
    status                => {type => 'enum', 'values' => [qw(declared handed_over postponed cancelled)], 'default' => 'declared'},
    team                  => {type => 'enum', 'values' => [qw(Compara Core Funcgen EnsemblGenomes Genebuild Outreach Variation Web Wormbase Production)]},
    assembly              => {type => 'enum', 'values' => [qw(N Y)]},
    gene_set              => {type => 'enum', 'values' => [qw(N Y)]},
    repeat_masking        => {type => 'enum', 'values' => [qw(N Y)]},
    stable_id_mapping     => {type => 'enum', 'values' => [qw(N Y)]},
    affy_mapping          => {type => 'enum', 'values' => [qw(N Y)]},
    biomart_affected      => {type => 'enum', 'values' => [qw(N Y)]},
    variation_pos_changed => {type => 'enum', 'values' => [qw(N Y)]},
    db_status             => {type => 'enum', 'values' => [qw(N/A unchanged patched new)]},
    db_type_affected      => {type => 'set',  'values' => [qw(cdna core funcgen otherfeatures rnaseq variation vega)]},
    priority              => {type => 'integer', 'not_null' => 1, 'default' => 2},
    is_current            => {type => 'integer', 'not_null' => 1, 'default' => 1}
  ],

  title_column          => 'title',
  inactive_flag_column  => 'is_current',

  relationships         => [
    species => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::ORM::Rose::Object::ChangelogSpecies',
      'map_from'    => 'changelog',
      'map_to'      => 'species'
    }
  ]
);

1;