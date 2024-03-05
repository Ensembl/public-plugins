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
use warnings;

package EnsEMBL::Mart::SiteDefs;

sub update_conf {
  $SiteDefs::ENSEMBL_MART_ENABLED           = 1;
  $SiteDefs::ENSEMBL_MART_PLUGIN_ENABLED    = 1;
  $SiteDefs::PERL_RLIMIT_AS                 = '8192:16384';

  # add biomart-perl to the path
  push @{$SiteDefs::ENSEMBL_API_LIBS}, "$SiteDefs::ENSEMBL_SERVERROOT/biomart-perl/lib";

  # ENV variables needed by biomart's cgi-bin scripts
  $SiteDefs::ENSEMBL_MART_CONF_DIR          = undef;                                   # use biomart-perl/conf dir by default
  $SiteDefs::ENSEMBL_MART_EXTERNAL_URL      = defer { $SiteDefs::ENSEMBL_SERVERNAME }; # defaults to the main site url

  # Set ENV vars from SiteDefs
  $SiteDefs::ENSEMBL_SETENV->{'ENSEMBL_MART_CONF_DIR'}      = 'ENSEMBL_MART_CONF_DIR';
  $SiteDefs::ENSEMBL_SETENV->{'ENSEMBL_MART_LOG_DIR'}       = 'ENSEMBL_LOGDIR';
  $SiteDefs::ENSEMBL_SETENV->{'ENSEMBL_MART_EXTERNAL_URL'}  = 'ENSEMBL_MART_EXTERNAL_URL';
}

1;
