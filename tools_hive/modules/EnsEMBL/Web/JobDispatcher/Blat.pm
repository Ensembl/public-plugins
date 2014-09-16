=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::JobDispatcher::Blat;

### Dispatcher to run the BLAT jobs
### It forces the hive to run BLAT jobs under Blat logic name instead of default Blast

use strict;
use warnings;

use parent qw(EnsEMBL::Web::JobDispatcher::Hive);

sub dispatch_job {
  ## @override
  my $self = shift;
  shift;

  return $self->SUPER::dispatch_job('Blat', @_);
}

sub delete_jobs {
  ## @override
  my $self = shift;
  shift;

  return $self->SUPER::delete_jobs('Blat', @_);
}

1;
