package EnsEMBL::ORM::Data::Rose::Changelog;

### NAME: EnsEMBL::ORM::Data::Rose::Changelog;

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
  my $self = shift;

  my $objects = EnsEMBL::ORM::Rose::Manager::Changelog->get_changelogs(
    query => [
      release_id => $self->hub->species_defs->ENSEMBL_VERSION,
    ],
    sort_by => 'team',
  );
  $self->data_objects(@$objects);
  return $objects;
}

1;
