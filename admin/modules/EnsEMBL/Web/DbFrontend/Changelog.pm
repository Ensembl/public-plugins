package EnsEMBL::Web::DbFrontend::Changelog;

### NAME: EnsEMBL::Web::DbFrontend::Changelog;

### STATUS: Under development

### DESCRIPTION:

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::DbFrontend);

sub init {
  my $self = shift;

  ## Custom values
  $self->{'record_select_columns'} = [qw(team title)];
  $self->{'record_table_columns'} = [qw(team created_by title status)];

  ## Alter default settings if required
  $self->{'show_fields'} = [qw(team title species content status assembly gene_set repeat_masking stable_id_mapping affy_mapping db_status notes)];
  $self->{'show_history'} = 1;
}

sub modify_form {
  my ($self, $param, $mode) = @_;

  $param->{'db_status'}{'label'} = 'Database changed';
  $param->{'release_id'}{'type'} = 'NoEdit';
  $param->{'release_id'}{'value'} = $self->hub->species_defs->ENSEMBL_VERSION;
}

1;
