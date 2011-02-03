package EnsEMBL::ORM::DbFrontend::Changelog;

### NAME: EnsEMBL::ORM::DbFrontend::Changelog;
### Settings for the CRUD interface to ensembl_production.changelog

### STATUS: Under development

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::ORM::DbFrontend);

sub init {
  my $self = shift;

  ## Custom values
  $self->{'record_select_columns'} = [qw(team title)];
  $self->{'record_table_columns'} = [qw(team created_by title status)];

  ## Alter default settings if required
  $self->{'show_fields'} = [qw(release_id team title species content status assembly gene_set repeat_masking stable_id_mapping affy_mapping db_status notes)];
  $self->{'show_tracking'} = 1;
  $self->{'pagination'} = 50;
}

sub modify_form {
  my ($self, $param, $mode) = @_;

  unshift @{$param->{'species'}{'values'}}, {'value' => '0', 'name' => 'All Species'};
  $param->{'species'}{'required'} = 1;
  $param->{'content'}{'class'} = '_tinymce';
  $param->{'db_status'}{'label'} = 'Database changed';
  $param->{'assembly'}{'label'} = 'Is this a new assembly?';
  $param->{'gene_set'}{'label'} = 'Has the gene set changed?';
  $param->{'repeat_masking'}{'label'} = 'Has the repeat masking changed?';
  $param->{'stable_id_mapping'}{'label'} = 'Does it need stable ID mapping?';
  $param->{'affy_mapping'}{'label'} = 'Does it need affy mapping?';
#  $param->{'biomart_affected'}{'label'} = 'Will BioMart need manual configuration?';

  $param->{'release_id'}{'type'} = 'NoEdit';
  $param->{'release_id'}{'value'} = $self->hub->species_defs->ENSEMBL_VERSION;
}

1;
