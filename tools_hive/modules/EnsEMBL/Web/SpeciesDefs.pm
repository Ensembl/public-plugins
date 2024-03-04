=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

sub hive_db {
  my $self = shift;
  my $db   = $self->multidb->{'DATABASE_WEB_HIVE'};

  return {
    'database'  => $db->{'NAME'},
    'host'      => $db->{'HOST'},
    'port'      => $db->{'PORT'},
    'username'  => $db->{'USER'}  || $self->DATABASE_WRITE_USER,
    'password'  => $db->{'PASS'}  || $self->DATABASE_WRITE_PASS
  };
}

sub hive_tools_list {
  ## Gets a list of all tools that need to be on the hive db
  my $self  = shift;
  my %tools = @{$self->ENSEMBL_TOOLS_LIST};
  my @tools = keys %tools;

  push @tools, 'Blat' if $tools{'Blast'};

  return sort @tools;
}

1;
