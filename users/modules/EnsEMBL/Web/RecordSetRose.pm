=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::RecordSetRose;

### RecordSet object that belongs to abother rose object - like user or group (session is not a rose object since there's no row corresponding to each session in db)

use strict;
use warnings;

use parent qw(EnsEMBL::Web::RecordSet);

sub save {
  ## Saves all the records in the set
  my ($self, $args) = @_;

  use Carp; Carp::cluck unless ref $args;

  if ($args->{'user'}) {
    $args->{'user'}->has_changes(1);
    $args->{'user'} = $args->{'user'}->rose_object;
  }

  return $self->SUPER::save($args);
}

sub clone_and_reset {
  ## Clones and resets the actual rose object
  my $self = shift;

  my ($record) = @{$self};

  return $self->new($record->clone_and_reset);
}

1;
