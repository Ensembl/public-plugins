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

package EnsEMBL::Tools::SiteDefs;

use strict;
use warnings;

sub validation {
  return {
    'type' => 'functionality'
  };
}

sub update_conf {

  $SiteDefs::OBJECT_TO_CONTROLLER_MAP->{'Tools'} = 'Page';
  $SiteDefs::OBJECT_TO_CONTROLLER_MAP->{'Blast'} = 'Config';

  # Add tl param
  push @{$SiteDefs::OBJECT_PARAMS}, [qw(Tools tl)];

  # Database key name for tools db as defined in MULTI.ini
  $SiteDefs::ENSEMBL_ORM_DATABASES->{'ticket'} = 'DATABASE_WEB_TOOLS';

  # Message to be displayed if tools db is down
  $SiteDefs::TOOLS_UNAVAILABLE_MESSAGE = 'Web Tools are temporarily not available.';

  # File that contains a message to be displayed if tools db is down (this takes precedence over TOOLS_UNAVAILABLE_MESSAGE)
  $SiteDefs::TOOLS_UNAVAILABLE_MESSAGE_FILE = defer { sprintf '%s/tools_db_unavailable_message', $SiteDefs::ENSEMBL_TMP_DIR };

  # Entries as added to the tools db ticket_type_name table (only edit this in plugins if new tool is being added)
  $SiteDefs::ENSEMBL_TOOLS_LIST = [
    'Blast'             => 'BLAST/BLAT',
    'VEP'               => 'Variant Effect Predictor',
    'LD'                => 'Linkage Disequilibrium Calculator',
    'VR'                => 'Variant Recoder',
    'FileChameleon'     => 'File Chameleon',
    'AssemblyConverter' => 'Assembly Converter',
    'IDMapper'          => 'ID History Converter',
    'AlleleFrequency'   => 'Allele Frequency Calculator',
    'VcftoPed'          => 'VCF to PED Converter',
    'DataSlicer'        => 'Data Slicer',
    'VariationPattern'  => 'Variation Pattern Finder',
    'Postgap'           => 'Post-GWAS',
  ];

  # Which dispatcher to be used for the jobs (provide the appropriate values in your plugins)
  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER = { 'Blast' => '', 'VEP' => '', 'AssemblyConverter' => '', 'IDMapper' => '', 'FileChameleon' => '' , 'AlleleFrequency' => '', 'VcftoPed' => '', 'DataSlier' => '', 'VariationPattern' => '', 'LD' => '', 'Postgap' => '', 'VR' => ''};

  # tmp directory for jobs i/o files - the final folder structure looks like ENSEMBL_USERDATA_DIR_TOOLS/temporary|persistent/ENSEMBL_TMP_SUBDIR_TOOLS/Blast|VEP
  $SiteDefs::ENSEMBL_TMP_DIR_TOOLS    = defer { $SiteDefs::ENSEMBL_USERDATA_DIR }; # keeping the base dir same as the main tmp dir
  $SiteDefs::ENSEMBL_TMP_SUBDIR_TOOLS = 'tools';

  # Flag to enable/disable tools
  $SiteDefs::ENSEMBL_BLAST_ENABLED  = 1;
  $SiteDefs::ENSEMBL_BLAT_ENABLED   = 1; # BLAT enable
  $SiteDefs::ENSEMBL_VEP_ENABLED    = 1;
  $SiteDefs::ENSEMBL_AC_ENABLED     = 1;
  $SiteDefs::ENSEMBL_IDM_ENABLED    = 1;
  $SiteDefs::ENSEMBL_FC_ENABLED     = 1;
  $SiteDefs::ENSEMBL_LD_ENABLED     = 1;
  $SiteDefs::ENSEMBL_VR_ENABLED     = 1;
  $SiteDefs::ENSEMBL_VP_ENABLED     = 1; # VCF to PED enable
  $SiteDefs::ENSEMBL_DS_ENABLED     = 1; # Data slicer enable
  $SiteDefs::ENSEMBL_PG_ENABLED     = 1; #Postgap enable

  # Add ensembl-vep and VEP_plugins to libs
  unshift @{$SiteDefs::ENSEMBL_API_LIBS}, "$SiteDefs::ENSEMBL_SERVERROOT/ensembl-vep/modules";
  push @{$SiteDefs::ENSEMBL_EXTRA_INC}, "$SiteDefs::ENSEMBL_SERVERROOT/VEP_plugins";

  # Leave it on if mechanism to fetch sequence by IDs is working
  $SiteDefs::ENSEMBL_BLAST_BY_SEQID = 1;

  # Number of species allowed to be selected on Blast species selection panel
  $SiteDefs::BLAST_SPECIES_SELECTION_LIMIT = 25;

  # Path to BLAT client
  $SiteDefs::ENSEMBL_BLAT_BIN_PATH = '/path/to/gfClient';

  # Dir containing BLAT's two bit files
  $SiteDefs::ENSEMBL_BLAT_TWOBIT_DIR = '/path/to/blat';

  # Script to convert BLAT alignment strings to BTOP
  $SiteDefs::ENSEMBL_BLAT_BTOP_SCRIPT = 'public-plugins/tools/utils/BLAT_alignments_to_BTOP.pl';

  # Path to File Chameleon script
  $SiteDefs::FILE_CHAMELEON_BIN_PATH = '/path/to/format_transcriber.pl'; 

  # FTP Path used by File Chameleon
  $SiteDefs::FILE_CAMELEON_FTP_URL = 'http://ftp.exampleftp.com/current/';

  # Path to Allele Frequency script
  $SiteDefs::ALLELE_FREQUENCY_BIN_PATH = '/path/to/allele_frequency.pl';

  # Path to VCF to PED script
  $SiteDefs::VCF_PED_BIN_PATH = '/path/to/vcftoped.pl';

  # Path to Data Slicer script
  $SiteDefs::DATA_SLICER_BIN_PATH = '/path/to/dataslicer.pl';

  # Path to variation pattern finder script
  $SiteDefs::VARIATION_PATTERN_BIN_PATH = '/path/to/variant_pattern_finder.pl';

  # Path to post gap script
  $SiteDefs::POSTGAP_BIN_PATH       = '/path/to/POSTGAP.py';
  $SiteDefs::POSTGAPHTML_BIN_PATH   = '/path/to/postgap_html_report.py';
  $SiteDefs::POSTGAP_TEMPLATE_FILE  = '/path/to/geneReport.html';

  # Upload file size limits
  $SiteDefs::ENSEMBL_TOOLS_CGI_POST_MAX = {
    'VEP'               =>  50 * 1024 * 1024,
    'AssemblyConverter' =>  50 * 1024 * 1024,
    'IDMapper'          =>  50 * 1024 * 1024,
  };

  # location of the VEP filter script accessible to the web machine for filtering Results pages output
  $SiteDefs::ENSEMBL_VEP_FILTER_SCRIPT = 'ensembl-vep/filter_vep';

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

  # site_type filter for ticket table (useful when using multiple sites against same tools database)
  $SiteDefs::ENSEMBL_TOOLS_SITETYPE = defer { $SiteDefs::ENSEMBL_SITETYPE };

  # Download URL domain for downloading FileChemelion out files if it's different than the current domain
  $SiteDefs::ENSEMBL_DOWNLOAD_URL = '';

  #1000Genome Rest URL
  $SiteDefs::GENOME_REST_FILE_URL  = "https://www.internationalgenome.org/api/beta/file/_search";

  #1000Genome tool variables
  $SiteDefs::PHASE1_PANEL_URL   = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/phase1_integrated_calls.20101123.ALL.panel";
  $SiteDefs::PHASE3_PANEL_URL   = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel";
  $SiteDefs::PHASE3_MALE_URL    = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_male_samples_v3.20130502.ALL.panel";

# Populations dropdown for 1000 genomes tools (data slicer, vcf2ped,..), dropdown value => caption (used in ThousandGenomeInputForm.pm), specific to human only
# if more species are supported, then this need to be moved to species ini file with each phase url as well
  $SiteDefs::THOUSANDG_POPULATIONS = {
    'phase1' => 'Phase 1',
    'phase3' => 'Phase 3'
  };

#FTP Url location of files for 1000Genomes tools (Data slicer, vcf2ped,...), It is a regular expression thats used by the rest call elastic search. These need to be specified in each plugin
  $SiteDefs::THOUSANDG_FILE_LOCATION = "";
}

1;
