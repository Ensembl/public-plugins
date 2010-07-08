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
}

sub modify_form {
  my ($self, $param, $mode) = @_;

  $param->{'db_status'}{'label'} = 'Database changed';
  $param->{'release_id'}{'type'} = 'NoEdit';
  $param->{'release_id'}{'value'} = $self->hub->species_defs->ENSEMBL_VERSION;
}

1;
