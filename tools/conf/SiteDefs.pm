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

  $SiteDefs::OBJECT_TO_SCRIPT->{'Tools'} = 'Page';

  # Database key name for tools db as defined in MULTI.ini
  $SiteDefs::ENSEMBL_ORM_DATABASES->{'ticket'} = 'DATABASE_WEB_TOOLS';

  # Entries as added to the tools db ticket_type_name table
  $SiteDefs::ENSEMBL_TOOLS_LIST = [ 'Blast' => 'BLAST/BLAT', 'VEP' => 'Variant Effect Predictor', 'AssemblyConverter' => 'Assembly Converter' ];

  # Which dispatcher to be used for the jobs (provide the appropriate values in your plugins)
  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER = { 'Blast' => '', 'VEP' => '', 'AssemblyConverter' => '' };

  # tmp directory for jobs i/o files
  $SiteDefs::ENSEMBL_TMP_DIR_TOOLS = defer { $SiteDefs::ENSEMBL_TMP_DIR.'/tools' };

  # Flag to enable/disable BLAST, VEP, Assembly Converter
  $SiteDefs::ENSEMBL_BLAST_ENABLED  = 1;
  $SiteDefs::ENSEMBL_VEP_ENABLED    = 1;
  $SiteDefs::ENSEMBL_AC_ENABLED     = 1;

  # Path to BLAT client
  $SiteDefs::ENSEMBL_BLAT_BIN_PATH = '/localsw/bin/gfClient';

  # Dir containing BLAT's two bit files
  $SiteDefs::ENSEMBL_BLAT_TWOBIT_DIR = '/ensemblweb/blat';

  # Script to convert BLAT alignment strings to BTOP
  $SiteDefs::ENSEMBL_BLAT_BTOP_SCRIPT = 'public-plugins/tools/utils/BLAT_alignments_to_BTOP.pl';

  # Path to CrossMap
  $SiteDefs::ASSEMBLY_CONVERTER_BIN_PATH = '/localsw/CrossMap-0.1.3/usr/local/bin/CrossMap.py';

  # Upload file size limits
  $SiteDefs::ENSEMBL_TOOLS_CGI_POST_MAX = {
    'VEP'               =>  50 * 1024 * 1024,
    'AssemblyConverter' =>  50 * 1024 * 1024,
  };

  # location of the VEP filter script accessible to the web machine for filtering Results pages output
  $SiteDefs::ENSEMBL_VEP_FILTER_SCRIPT = 'ensembl-tools/scripts/variant_effect_predictor/filter_vep.pl';

  # Command line options for VEP filter script
  $SiteDefs::ENSEMBL_VEP_FILTER_SCRIPT_OPTIONS = {
    '-host'         => undef,
    '-user'         => undef,
    '-port'         => undef,
    '-pass'         => undef
  };
}


1;
