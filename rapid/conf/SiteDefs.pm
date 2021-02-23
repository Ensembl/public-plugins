=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

use strict;

package EnsEMBL::RapidRelease::SiteDefs;

sub update_conf {
  $SiteDefs::ENSEMBL_SUBTYPE          = 'Rapid Release';
  $SiteDefs::FIRST_RELEASE_VERSION    = 100; ## Don't update this!
  $SiteDefs::ENSEMBL_RELEASE_DATE = '23 February 2021';
  $SiteDefs::NO_REGULATION            = 1;
  $SiteDefs::NO_VARIATION             = 1;
  $SiteDefs::NO_COMPARA               = 1;
  $SiteDefs::ENSEMBL_MART_ENABLED     = 0;

  $SiteDefs::ENSEMBL_EXTERNAL_SEARCHABLE    = 0;

  $SiteDefs::ENSEMBL_PRIMARY_SPECIES  = 'Camarhynchus_parvulus_GCA_902806625.1';
}

1;
