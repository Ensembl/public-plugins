package EnsEMBL::ORM::DbFrontend::News;

### NAME: EnsEMBL::ORM::DbFrontend::News;

### STATUS: Under development

### DESCRIPTION:

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::ORM::DbFrontend);

sub init {
  my $self = shift;

  ## Custom values
  $self->{'record_select_columns'} = [qw(title)];
  $self->{'record_table_columns'} = [qw(title status)];

  ## Alter default settings if required
  $self->{'show_fields'} = [qw(release_id title content species priority status)];
  $self->{'show_primary_key'} = 0;
}

sub modify_form {
  my ($self, $param, $mode) = @_;

  $param->{'release_id'}{'type'} = 'NoEdit';
  $param->{'release_id'}{'value'} = $self->hub->species_defs->ENSEMBL_VERSION;
}

1;
