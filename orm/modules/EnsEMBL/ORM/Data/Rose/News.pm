package EnsEMBL::ORM::Data::Rose::News;

### NAME: EnsEMBL::ORM::Data::Rose::News;
### Wrapper for one or more EnsEMBL::ORM::Rose::Object::NewsItem objects

### DESCRIPTION:

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::Manager::News;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_classes {
### Set custom class names, as they are not quite the same as the table name
  my $self = shift;
  $self->{'_object_class'} = 'EnsEMBL::ORM::Rose::Object::NewsItem';
  $self->{'_manager_class'} = 'EnsEMBL::ORM::Rose::Manager::News';
}

sub fetch_all {
### Custom query - for the changelog output, we normally only want to 
### see the results for one release at a time
  my $self = shift;
  my $release_id = $self->hub->param('release')
                      || $self->hub->species_defs->ENSEMBL_VERSION;
  my $objects = $self->{'_manager_class'}->get_newsitems(
    query => [
      release_id => $release_id,
    ],
  );
  $self->data_objects(@$objects);
  return $objects;
}

1;
