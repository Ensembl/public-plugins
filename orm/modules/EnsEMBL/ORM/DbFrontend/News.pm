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

  ## Alter default settings if required
  $self->{'show_fields'} = [qw(title content)];
  $self->{'show_primary_key'} = 0;
}

1;
