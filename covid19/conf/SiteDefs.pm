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

use strict;

package EnsEMBL::Covid19Public::SiteDefs;

sub update_conf {

  my $machine_name = `echo \$HOSTNAME`;
  chomp $machine_name;

  $SiteDefs::ENSEMBL_PORT             = 8000;
  $SiteDefs::ENSEMBL_PROXY_PORT       = 80;
  $SiteDefs::ENSEMBL_SUBTYPE          = 'COVID-19';
  $SiteDefs::ENSEMBL_COVID19_VERSION  = 3;
  $SiteDefs::ENSEMBL_RELEASE_DATE     = 'Jan 2022';

  $SiteDefs::UDC_CACHEDIR             = '/data/UDCcache';
  $SiteDefs::ENSEMBL_STATIC_SERVER    = '';
  $SiteDefs::ENSEMBL_REST_URL         = '';
  $SiteDefs::SPECIES_IMAGE_DIR        = defer { $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/covid19/'.$SiteDefs::DEFAULT_SPECIES_IMG_DIR };

  $SiteDefs::NO_KARYOTYPE             = 1;
  $SiteDefs::NO_REGULATION            = 1;
  $SiteDefs::NO_VARIATION             = 0;
  $SiteDefs::NO_COMPARA               = 0;
  $SiteDefs::ENSEMBL_MART_ENABLED     = 0;
  $SiteDefs::NO_PUBLIC_MYSQL          = 1;

  $SiteDefs::ENSEMBL_EXTERNAL_SEARCHABLE    = 0;

  $SiteDefs::ENSEMBL_PRIMARY_SPECIES  = 'Sars_cov_2'; # Default species

  $SiteDefs::PRODUCTION_NAMES         = [qw(
                                            sars_cov_2
                                            viruses_orthocoronavirinae
                                            viruses_mixed
                                          )];
  push @{$SiteDefs::ENSEMBL_VEP_PLUGIN_CONFIG_FILES}, $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/covid19/conf/vep_plugins_web_config.txt';
}

1;
