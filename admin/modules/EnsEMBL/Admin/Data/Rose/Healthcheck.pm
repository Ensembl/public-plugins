package EnsEMBL::Admin::Data::Rose::Healthcheck;

### NAME: EnsEMBL::Admin::Data::Rose::Healthcheck;
### Wrapper for one or more EnsEMBL::ORM::Rose::Object::Healthcheck objects

### DESCRIPTION:

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::Admin::Rose::Manager::Healthcheck;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_classes {
### Set custom class names, as they are not quite the same as the URL
  my $self = shift;
  $self->{'_object_class'} = 'EnsEMBL::Admin::Rose::Object::Report';
  $self->{'_manager_class'} = 'EnsEMBL::Admin::Rose::Manager::Report';
}

sub set_primary_keys {
  my $self = shift;
  $self->{'_primary_keys'} = [qw(report_id)];
}


