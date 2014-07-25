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

package EnsEMBL::Tools::SiteDefs;

use strict;

sub update_conf {

  $SiteDefs::OBJECT_TO_SCRIPT->{'Tools'}        = 'Page';

  $SiteDefs::ENSEMBL_ORM_DATABASES->{'ticket'}  = 'DATABASE_WEB_TOOLS';                             # Database key name for tools db as defined in MULTI.ini

  $SiteDefs::ENSEMBL_TOOLS_LIST                 = [ 'Blast' => 'BLAST/BLAT', 'VEP' => 'Variant Effect Predictor', 'AssemblyConverter' => 'Assembly Converter' ];
                                                                                                    # Entries as added to the tools db ticket_type_name table
  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER       = { 'Blast' => '', 'VEP' => '', 'AssemblyConverter' => '' };                   # Which dispatcher to be used for the jobs

  $SiteDefs::ENSEMBL_TMP_DIR_TOOLS              = defer { $SiteDefs::ENSEMBL_TMP_DIR.'/tools' };    # tmp directory for jobs i/o files
  $SiteDefs::ENSEMBL_BLAST_ENABLED              = 1;                                                # Flag to enable/disable BLAST
  $SiteDefs::ENSEMBL_BLAT_BIN_PATH              = '/localsw/bin/gfClient';                          # Path to BLAT client
  $SiteDefs::ENSEMBL_BLAT_BTOP_SCRIPT           = 'sanger-plugins/tools/utils/BLAT_alignments_to_BTOP.pl';  # Script to convert BLAT alignments to BTOP
  $SiteDefs::ASSEMBLY_CONVERTER_BIN_PATH        = '/localsw/CrossMap-0.1.3/usr/local/bin/CrossMap.py';                          # Path to CrossMap
  $SiteDefs::ENSEMBL_VEP_ENABLED                = 1;                                                # Flag to enable/disable VEP
  $SiteDefs::ENSEMBL_AC_ENABLED                 = 1;                                                # Flag to enable/disable Assembly Converter
  $SiteDefs::ENSEMBL_VEP_CGI_POST_MAX           = 52428800;                                         # 50MB limit for VEP input files
  $SiteDefs::ENSEMBL_AC_CGI_POST_MAX            = 52428800;                                         # 50MB limit for Assembly Converter input files
  $SiteDefs::ENSEMBL_VEP_FILTER_SCRIPT          = 'ensembl-tools/scripts/variant_effect_predictor/filter_vep.pl';
                                                                                                    # location of the VEP filter script accessible to the web machine for filtering Results pages output
  $SiteDefs::ENSEMBL_VEP_FILTER_SCRIPT_OPTIONS  = {                                                 # Command line options for VEP filter script
    '-host'         => undef,
    '-user'         => undef,
    '-port'         => undef,
    '-pass'         => undef
  };
}


1;
