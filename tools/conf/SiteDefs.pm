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

package EnsEMBL::Tools::SiteDefs;

use strict;

sub update_conf {

  $SiteDefs::OBJECT_TO_CONTROLLER_MAP->{'Tools'} = 'Page';
  $SiteDefs::OBJECT_TO_CONTROLLER_MAP->{'Blast'} = 'Config';

  # Database key name for tools db as defined in MULTI.ini
  $SiteDefs::ENSEMBL_ORM_DATABASES->{'ticket'} = 'DATABASE_WEB_TOOLS';

  # Entries as added to the tools db ticket_type_name table (only edit this in plugins if new tool is being added)
  $SiteDefs::ENSEMBL_TOOLS_LIST = [
    'Blast'             => 'BLAST/BLAT',
    'VEP'               => 'Variant Effect Predictor',
    'FileChameleon'     => 'File Chameleon',
    'AssemblyConverter' => 'Assembly Converter',
    'IDMapper'          => 'ID History Converter',
    'AlleleFrequency'   => 'Allele Frequency Calculator',
    'VcftoPed'          => 'VCF to PED Converter',
  ];

  # Which dispatcher to be used for the jobs (provide the appropriate values in your plugins)
  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER = { 'Blast' => '', 'VEP' => '', 'AssemblyConverter' => '', 'IDMapper' => '', 'FileChameleon' => '' , 'AlleleFrequency' => '', 'VcftoPed' => ''};

  # tmp directory for jobs i/o files - the final folder structure looks like ENSEMBL_TMP_DIR_TOOLS/temporary|persistent/ENSEMBL_TMP_SUBDIR_TOOLS/Blast|VEP
  $SiteDefs::ENSEMBL_TMP_DIR_TOOLS    = defer { $SiteDefs::ENSEMBL_TMP_DIR }; # keeping the base dir same as the main tmp dir
  $SiteDefs::ENSEMBL_TMP_SUBDIR_TOOLS = 'tools';

  # Flag to enable/disable tools
  $SiteDefs::ENSEMBL_BLAST_ENABLED  = 1;
  $SiteDefs::ENSEMBL_VEP_ENABLED    = 1;
  $SiteDefs::ENSEMBL_AC_ENABLED     = 1;
  $SiteDefs::ENSEMBL_IDM_ENABLED    = 1;
  $SiteDefs::ENSEMBL_FC_ENABLED     = 1;

  # Leave it on if mechanism to fetch sequence by IDs is working
  $SiteDefs::ENSEMBL_BLAST_BY_SEQID = 1;

  # Path to BLAT client
  $SiteDefs::ENSEMBL_BLAT_BIN_PATH = '/path/to/gfClient';

  # Dir containing BLAT's two bit files
  $SiteDefs::ENSEMBL_BLAT_TWOBIT_DIR = '/path/to/blat';

  # Script to convert BLAT alignment strings to BTOP
  $SiteDefs::ENSEMBL_BLAT_BTOP_SCRIPT = 'public-plugins/tools/utils/BLAT_alignments_to_BTOP.pl';

  # Path to CrossMap
  $SiteDefs::ASSEMBLY_CONVERTER_BIN_PATH = '/path/to/CrossMap.py';

  # Path to File Chameleon script
  $SiteDefs::FILE_CHAMELEON_BIN_PATH = '/path/to/format_transcriber.pl'; 

  # Path to Allele Frequency script
  $SiteDefs::ALLELE_FREQUENCY_BIN_PATH = '/path/to/allele_frequency.pl';

  # Path to VCF to PED script
  $SiteDefs::VCF_PED_BIN_PATH = '/path/to/vcftoped.pl';

  # Upload file size limits
  $SiteDefs::ENSEMBL_TOOLS_CGI_POST_MAX = {
    'VEP'               =>  50 * 1024 * 1024,
    'AssemblyConverter' =>  50 * 1024 * 1024,
    'IDMapper'          =>  50 * 1024 * 1024,
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

  # Config files for VEP plugins (each file overrides the configs in the previous one in the list)
  $SiteDefs::ENSEMBL_VEP_PLUGIN_CONFIG_FILES  = [
                                                  $SiteDefs::ENSEMBL_SERVERROOT.'/VEP_plugins/plugin_config.txt', # VEP_plugins is cloned from github.com/ensembl-variation/VEP_plugins
                                                  $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/tools/conf/vep_plugins_web_config.txt'
                                                ];

  # Tickets will expire after 10 days, and user will warned when less than three days are left
  $SiteDefs::ENSEMBL_TICKETS_VALIDITY         = 10 * 24 * 60 * 60;
  $SiteDefs::ENSEMBL_TICKETS_VALIDITY_WARNING = 3  * 24 * 60 * 60;

  #1000Genome Rest URL
  $SiteDefs::GENOME_REST_FILE_URL  = "http://www.internationalgenome.org/api/beta/file/_search";

  #1000Genome tool variables
  $SiteDefs::PHASE1_PANEL_URL   = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/phase1_integrated_calls.20101123.ALL.panel";
  $SiteDefs::PHASE3_PANEL_URL   = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel";
  $SiteDefs::PHASE3_MALE_URL    = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_male_samples_v3.20130502.ALL.panel";

}

1;
