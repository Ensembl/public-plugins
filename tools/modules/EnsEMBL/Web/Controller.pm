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

package EnsEMBL::Web::Controller;

use strict;
use warnings;

use previous qw(OBJECT_PARAMS upload_size_limit);

sub OBJECT_PARAMS {
  return [ @{PREV::OBJECT_PARAMS()}, [ 'Tools' => 'tl' ] ];
}

sub upload_size_limit {
  my $self = shift;
  return ($self->type || '') eq 'Tools' && $self->action eq 'VEP' ? $self->species_defs->ENSEMBL_VEP_CGI_POST_MAX : $self->PREV::upload_size_limit;
}

1;
