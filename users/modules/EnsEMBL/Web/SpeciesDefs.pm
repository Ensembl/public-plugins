=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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
use warnings;

use previous qw(register_orm_databases);

sub accounts_db {
  my $self = shift;
  my $db   = $self->multidb->{'DATABASE_ACCOUNTS'};

  return {
    'database'  => $db->{'NAME'},
    'host'      => $db->{'HOST'},
    'port'      => $db->{'PORT'},
    'username'  => $db->{'USER'}  || $self->DATABASE_WRITE_USER,
    'password'  => $db->{'PASS'}  || $self->DATABASE_WRITE_PASS
  };
}

sub register_orm_databases {
  my $self = shift;

  $self->ENSEMBL_ORM_DATABASES->{'user'} = $self->accounts_db;

  return $self->PREV::register_orm_databases;
}

1;
