package EnsEMBL::Web::Data::Analysis;

use strict;
use warnings;

use base qw/EnsEMBL::Web::Data::Genomic/;

__PACKAGE__->table('analysis');
__PACKAGE__->set_primary_key('analysis_id');

__PACKAGE__->add_queriable_fields(
    created         => 'datetime',
    logic_name      => 'varchar(128)',
    db              => 'varchar(120)',
    db_version      => 'varchar(40)',
    db_file         => 'varchar(120)',
    program         => 'varchar(80)',
    program_version => 'varchar(40)',
    program_file    => 'varchar(80)',
    parameters      => 'text',
    module          => 'varchar(80)',
    module_version  => 'varchar(40)',
    gff_source      => 'varchar(40)',
    gff_feature     => 'varchar(40)',
);

__PACKAGE__->might_have(analysis_description => 'EnsEMBL::Web::Data::AnalysisDescription' => qw/display_label description/);

1;
