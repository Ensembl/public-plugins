package EnsEMBL::ORM::Data::Rose::Changelog;

### NAME: EnsEMBL::ORM::Data::Rose::Changelog;
### Wrapper for one or more EnsEMBL::ORM::Rose::Object::Changelog objects

### STATUS: Under Development

### DESCRIPTION:

use strict;
use warnings;
no warnings qw(uninitialized);

use EnsEMBL::ORM::Rose::Manager::Changelog;
use base qw(EnsEMBL::ORM::Data::Rose);

sub set_primary_keys {
  my $self = shift;
  $self->{'_primary_keys'} = [qw(changelog_id)];
}

sub fetch_all {
### Custom query - for the changelog output, we normally only want to 
### see the results for one release at a time
  my $self = shift;
  my $release_id = $self->hub->param('release') 
                      || $self->hub->species_defs->ENSEMBL_VERSION;

  my $objects = EnsEMBL::ORM::Rose::Manager::Changelog->get_changelogs(
    query => [
      release_id => $release_id,
    ],
    sort_by => 'team',
  );
  $self->data_objects(@$objects);
  return $objects;
}

1;
