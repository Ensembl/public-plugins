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
use warnings;

use previous qw(register_orm_databases);

sub accounts_db {
  my $self = shift;
  my $db   = $self->multidb->{'DATABASE_ACCOUNTS'};

  return {
    'NAME'    => $db->{'NAME'},
    'HOST'    => $db->{'HOST'},
    'PORT'    => $db->{'PORT'},
    'DRIVER'  => $db->{'DRIVER'}  || 'mysql',
    'USER'    => $db->{'USER'}    || $self->DATABASE_WRITE_USER,
    'PASS'    => $db->{'PASS'}    || $self->DATABASE_WRITE_PASS
  };
}

sub register_orm_databases {
  my $self  = shift;
  my $db    = $self->accounts_db;

  $self->ENSEMBL_ORM_DATABASES->{'user'} = {
    'database'  => $db->{'NAME'},
    'host'      => $db->{'HOST'},
    'port'      => $db->{'PORT'},
    'username'  => $db->{'USER'},
    'password'  => $db->{'PASS'}
  };

  return $self->PREV::register_orm_databases;
}

1;
