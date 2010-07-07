package EnsEMBL::ORM::Data::Rose::News;

### NAME: EnsEMBL::ORM::Data::Rose::News;

### STATUS: Under Development

### DESCRIPTION:

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::Manager::News;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_classes {
  my $self = shift;
  $self->{'_object_class'} = 'EnsEMBL::ORM::Rose::Object::NewsItem';
  $self->{'_manager_class'} = 'EnsEMBL::ORM::Rose::Manager::News';
}

sub set_relationships {
  my $self = shift;
  $self->set_edit_tracking;
}

sub fetch_all {
  my $self = shift;
  my $objects = $self->{'_manager_class'}->get_newsitems(
    query => [
      release_id => $self->hub->species_defs->ENSEMBL_VERSION,
    ],
  );
  $self->data_objects(@$objects);
  return $objects;
}

1;
