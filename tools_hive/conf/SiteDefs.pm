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

package EnsEMBL::Tools_hive::SiteDefs;

### tools_hive plugin is a backend for running the ensembl tools jobs (BLAST, BLAT, VEP etc) using ensembl-hive.
### With this plugin, the jobs that are submitted by the website (via the tools plugin) are saved in the
### ENSEMBL_WEB_HIVE db and another process called 'beekeeper' (that could possibly be running on a different
### machine) continually looks at that database, runs the newly submitted jobs on LSF farm or on
### the local machine (LOCAL) where this process itself is running.

use strict;

sub update_conf {

  $SiteDefs::ENSEMBL_HIVE_ERROR_MESSAGE         = '';                                               # Error message to be displayed in case code throws a HiveError exception (can be HTML)
  $SiteDefs::ENSEMBL_HIVE_DB_NOT_AVAILABLE      = 0;                                                # Flag if on, jobs will not get submitted to hive db (ENSEMBL_HIVE_ERROR_MESSAGE is displayed when submitting jobs)

  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER       = { 
                                                    'Blast'             => 'Hive', 
                                                    'VEP'               => 'Hive', 
                                                    'AssemblyConverter' => 'Hive', 
                                                  };                                                # Overriding tools plugin variable
  $SiteDefs::ENSEMBL_HIVE_HOSTS                 = [];                                               # For LOCAL, the machine that runs the beekeeper unless it's same as the web server
                                                                                                    # For LSF, list of hosts corresponding to the queues for all jobs plus the machine where
                                                                                                    # beekeeper is running unless it's same as the web server
  $SiteDefs::ENSEMBL_HIVE_HOSTS_CODE_LOCATION   = $SiteDefs::ENSEMBL_SERVERROOT;                    # path from where hive hosts can access ensembl code (same as web root for jobs running on local machine)
  $SiteDefs::ENSEMBL_TOOLS_PIPELINE_PACKAGE     = 'EnsEMBL::Web::PipeConfig::Tools_conf';           # package read by init_pipeline.pl script from hive to create the hive database
  $ENV{'EHIVE_ROOT_DIR'}                        = $SiteDefs::ENSEMBL_SERVERROOT.'/ensembl-hive/';   # location from there hive scripts on the web server (not the hive hosts) can access the hive API

  push @SiteDefs::ENSEMBL_LIB_DIRS, "$SiteDefs::ENSEMBL_SERVERROOT/ensembl-hive/modules";

  @SiteDefs::ENSEMBL_TOOLS_LIB_DIRS = qw(
    ensembl
    ensembl-hive
    ensembl-variation
    ensembl-funcgen
    ensembl-tools
    ensembl-webcode
    public-plugins
    sanger-plugins
  );

  $SiteDefs::ENSEMBL_TOOLS_PERL_BIN             = '/usr/bin/perl';                                  # Path to perl bin for machine running the job
  $SiteDefs::ENSEMBL_TOOLS_BIOPERL_DIR          = defer { $SiteDefs::BIOPERL_DIR };                 # Location of bioperl on the hive host machine

  # BLAST configs
  $SiteDefs::ENSEMBL_BLAST_RUN_LOCAL            = 1;                                                # Flag if on, will run blast jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_BLAST_QUEUE                = 'blast';                                          # LSF or LOCAL queue for blast jobs
  $SiteDefs::ENSEMBL_BLAST_LSF_TIMEOUT          = undef;                                            # Max timelimit a blast job is allowed to run on LSF
  $SiteDefs::ENSEMBL_BLAST_ANALYSIS_CAPACITY    = 24;                                               # Number of jobs that can be run parallel in the blast queue (LSF or LOCAL)
  $SiteDefs::ENSEMBL_NCBIBLAST_BIN_PATH         = '/path/to/ncbi-blast/bin';                        # path to blast executables on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_NCBIBLAST_MATRIX           = '/path/to/ncbi-blast/data';                       # path to blast matrix files on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_NCBIBLAST_DATA_PATH        = "/path/to/genes";                                 # path for the blast index files (other than DNA) on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_NCBIBLAST_DATA_PATH_DNA    = "/path/to/blast/dna";                             # path for the blast DNA index files on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_REPEATMASK_BIN_PATH        = '/path/to/RepeatMasker';                          # path to RepeatMasker executable on the  LSF host (or local machine if job running locally)

  # BLAT configs
  $SiteDefs::ENSEMBL_BLAT_RUN_LOCAL             = 1;                                                # Flag if on, will run blat jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_BLAT_QUEUE                 = 'toolsgeneral';                                   # LSF or LOCAL queue for blat jobs
  $SiteDefs::ENSEMBL_BLAT_LSF_TIMEOUT           = undef;                                            # Max timelimit a blat job is allowed to run on LSF
  $SiteDefs::ENSEMBL_BLAT_ANALYSIS_CAPACITY     = 4;                                                # Number of jobs that can be run parallel in the blat queue (LSF or LOCAL)
  $SiteDefs::ENSEMBL_BLAT_TWOBIT_DIR            = "/path/to/blat/twobit";                           # location where blat twobit files are located on LSF node (or local machine if job running locally)

  # VEP configs
  $SiteDefs::ENSEMBL_VEP_RUN_LOCAL              = 1;                                                # Flag if on, will run VEP jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_VEP_QUEUE                  = 'VEP';                                            # LSF or LOCAL queue for VEP jobs
  $SiteDefs::ENSEMBL_VEP_LSF_TIMEOUT            = '3:00';                                           # Max timelimit a VEP job is allowed to run on LSF
  $SiteDefs::ENSEMBL_VEP_ANALYSIS_CAPACITY      = 24;                                               # Number of jobs that can be run parallel in the VEP queue (LSF or LOCAL)
  $SiteDefs::ENSEMBL_VEP_CACHE_DIR              = "/path/to/vep/cache";                             # path to vep cache files
  $SiteDefs::ENSEMBL_VEP_SCRIPT_DEFAULT_OPTIONS = {                                                 # Default options for command line vep script (keys with value undef get ignored)
    '--host'        => undef,                                                                       # Database host (defaults to ensembldb.ensembl.org)
    '--user'        => undef,                                                                       # Defaults to 'anonymous'
    '--password'    => undef,                                                                       # Not used by default
    '--port'        => undef,                                                                       # Defaults to 5306
    '--fork'        => 4,                                                                           # Enable forking, using 4 forks
  };
  $SiteDefs::ENSEMBL_VEP_SCRIPT                 = 'ensembl-tools/scripts/variant_effect_predictor/variant_effect_predictor.pl';
                                                                                                    # location of the VEP script accessible to the local machine or LSF host running the job
  $SiteDefs::ENSEMBL_VEP_TO_WEB_SCRIPT          = 'public-plugins/tools/utils/vep_to_web.pl';       # location of the VEP script accessible to the local machine or LSF host to parse VCF results

  # Assembly Converter configs
  $SiteDefs::ENSEMBL_AC_RUN_LOCAL               = 1;                                                # Flag if on, will run AC jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_AC_QUEUE                   = 'toolsgeneral';                                   # LSF or LOCAL queue for AC jobs
  $SiteDefs::ENSEMBL_AC_LSF_TIMEOUT             = undef;                                            # Max timelimit an AC job is allowed to run on LSF
  $SiteDefs::ENSEMBL_AC_ANALYSIS_CAPACITY       = 4;                                                # Number of jobs that can be run parallel in the queue (LSF or LOCAL)

}

1;
