package EnsEMBL::ORM::DbFrontend::User;

### NAME: EnsEMBL::ORM::DbFrontend::User;

### STATUS: Under development

### DESCRIPTION:

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::ORM::DbFrontend);

sub init {
  my $self = shift;

  ## Alter default settings if required
  $self->{'show_fields'} = [qw(name email organisation)];
  $self->{'show_primary_key'} = 0;
}

sub modify_form {
  my ($self, $param, $mode) = @_;

}

1;
