=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::SpeciesDefs;

use strict;

sub set_userdb_details_for_rose {
  my $self = shift;
  
  $self->ENSEMBL_ORM_DATABASES->{'user'} = {
    'database'  => $self->ENSEMBL_USERDB_NAME,
    'host'      => $self->ENSEMBL_USERDB_HOST,
    'port'      => $self->ENSEMBL_USERDB_PORT,
    'username'  => $self->ENSEMBL_USERDB_USER,
    'password'  => $self->ENSEMBL_USERDB_PASS
  };
}

1;
