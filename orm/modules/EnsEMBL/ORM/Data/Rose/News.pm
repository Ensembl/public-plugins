package EnsEMBL::ORM::Data::Rose::News;

### NAME: EnsEMBL::ORM::Data::Rose::News;
### Wrapper for one or more EnsEMBL::ORM::Rose::Object::NewsItem objects

### DESCRIPTION:

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::Manager::NewsItem;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_classes {
### Set custom class names, as they are not quite the same as the URL
  my $self = shift;
  $self->{'_object_class'} = 'EnsEMBL::ORM::Rose::Object::NewsItem';
  $self->{'_manager_class'} = 'EnsEMBL::ORM::Rose::Manager::NewsItem';
}

sub set_primary_keys {
  my $self = shift;
  $self->{'_primary_keys'} = [qw(news_item_id)];
}

sub fetch_all {
### Custom query - for the news output, we normally only want to 
### see the results for one release at a time
  my $self = shift;
  my $release_id = $self->hub->param('release')
                      || $self->hub->species_defs->ENSEMBL_VERSION;
  my $objects = $self->{'_manager_class'}->get_newsitems(
    query => [
      release_id  => $release_id,
      !content    => '', ## not empty
    ],
  );
  $self->data_objects(@$objects);
  return $objects;
}

sub fetch_published {
### Custom query - get only the published news for a release
### (used for public display, as opposed to CRUD interface)
  my $self = shift;
  my $release_id = $self->hub->param('release')
                      || $self->hub->species_defs->ENSEMBL_VERSION;
  my $objects = $self->{'_manager_class'}->get_newsitems(
    query => [
      release_id => $release_id,
      status     => 'published',
      !content    => '', ## not empty
    ],
  );
  $self->data_objects(@$objects);
  return $objects;
}

1;
