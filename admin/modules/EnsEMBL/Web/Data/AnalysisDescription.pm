package EnsEMBL::Web::Data::AnalysisDescription;

use strict;
use warnings;

use base qw/EnsEMBL::Web::Data/;
use EnsEMBL::Web::DBSQL::CoreDBConnection (__PACKAGE__->species_defs);

__PACKAGE__->table('analysis_description');
__PACKAGE__->set_primary_key('analysis_id');

__PACKAGE__->add_queriable_fields(
    display_label   => 'varchar(255)',
    description     => 'text',
    displayable     => 'tinyint',
    web_data        => 'text',
);



1;
