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

package EnsEMBL::Tools_hive::SiteDefs;

use strict;

sub update_conf {

  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER       = { 
                                                    'Blast'             => 'Hive', 
                                                    'VEP'               => 'Hive', 
                                                    'AssemblyConverter' => 'Hive', 
                                                  };           # Overriding tools plugin variable
  $SiteDefs::ENSEMBL_LSF_HOSTS                  = [];                                               # List of hosts where LSF jobs will be run
  $SiteDefs::ENSEMBL_LSF_CODE_LOCATION          = $SiteDefs::ENSEMBL_SERVERROOT;                    # path from where LSF hosts can access ensembl code (same as web root for jobs running on local machine)
  $SiteDefs::ENSEMBL_TOOLS_PIPELINE_PACKAGE     = 'EnsEMBL::Web::PipeConfig::Tools_conf';           # package read by init_pipeline.pl script from hive to create the hive database
  $ENV{'EHIVE_ROOT_DIR'}                        = $SiteDefs::ENSEMBL_SERVERROOT.'/ensembl-hive/';   # location from there hive scripts on the web server (not the LSF host) can access the hive API

  push @SiteDefs::ENSEMBL_LIB_DIRS, "$SiteDefs::ENSEMBL_SERVERROOT/ensembl-hive/modules";

  @SiteDefs::ENSEMBL_TOOLS_LIB_DIRS = qw(
    ensembl/modules
    ensembl-hive/modules
    ensembl-variation/modules
    ensembl-funcgen/modules
    ensembl-tools/scripts/variant_effect_predictor
    ensembl-webcode/conf
    ensembl-webcode/modules
    public-plugins/tools/modules
    public-plugins/tools_hive/modules
  );

  $SiteDefs::ENSEMBL_TOOLS_PERL_BIN             = '/usr/local/bin/perl';                            # Path to perl bin for machine running the job
  $SiteDefs::ENSEMBL_TOOLS_BIOPERL_DIR          = $SiteDefs::BIOPERL_DIR;                           # Location of bioperl on the LSF host machine (will be same as BIOPERL_DIR for jobs running locally)

  # BLAST configs
  my $release = "release-".$SiteDefs::ENSEMBL_VERSION;
  $SiteDefs::ENSEMBL_BLAST_LSF_QUEUE            = 'blast';                                          # LSF queue for blast jobs (not needed for local jobs)
  $SiteDefs::ENSEMBL_BLAST_LSF_TIMEOUT          = undef;                                            # Max timelimit a blast job is allowed to run
  $SiteDefs::ENSEMBL_BLAST_ANALYSIS_CAPACITY    = 24;                                               # Number of jobs that can be run parallel in LSF in the blast queue
  $SiteDefs::ENSEMBL_NCBIBLAST_BIN_PATH         = '/localsw/bin/ncbi-blast/bin';                    # path to blast executables on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_NCBIBLAST_MATRIX           = '/localsw/bin/ncbi-blast/bin/data';               # path to blast matrix files on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_NCBIBLAST_DATA_PATH        = "/data_ensembl/blastdb/ensembl/$release/genes";   # path for the blast index files (other than DNA) on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_NCBIBLAST_DATA_PATH_DNA    = "/data_ensembl/blastdb/ensembl/$release/genomic"; # path for the blast DNA index files on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_REPEATMASK_BIN_PATH        = '/localsw/bin/RepeatMasker';                      # path to RepeatMasker executable on the  LSF host (or local machine if job running locally)

  # BLAT configs
  $SiteDefs::ENSEMBL_BLAT_RUN_LOCAL             = 1;                                                # Flag if on, will run blat jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_BLAT_LOCAL_QUEUE           = 'blat_local';                                     # LOCAL meadow resource for BLAT jobs
  $SiteDefs::ENSEMBL_BLAT_LSF_QUEUE             = 'toolsgeneral';                                   # LSF queue for blat jobs
  $SiteDefs::ENSEMBL_BLAT_LSF_TIMEOUT           = undef;                                            # Max timelimit a blat job is allowed to run
  $SiteDefs::ENSEMBL_BLAT_ANALYSIS_CAPACITY     = 4;                                                # Number of jobs that can be run parallel in LSF in the tools queue
  $SiteDefs::ENSEMBL_BLAT_TWOBIT_DIR            = '/data_ensembl/blat/ensembl';                     # location where blat twobit files are located on LSF node

  # VEP configs
  $SiteDefs::ENSEMBL_VEP_LSF_QUEUE              = 'VEP';                                            # LSF queue for VEP jobs, if running on farm
  $SiteDefs::ENSEMBL_VEP_LSF_TIMEOUT            = '3:00';                                           # Max timelimit a VEP job is allowed to run
  $SiteDefs::ENSEMBL_VEP_ANALYSIS_CAPACITY      = 24;                                               # Number of jobs that can be run parallel in LSF in the queue
  $SiteDefs::ENSEMBL_VEP_CACHE_DIR              = '/data_ensembl/vep/'.$SiteDefs::ENSEMBL_VERSION;  # path to vep cache files
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
  $SiteDefs::ENSEMBL_AC_LOCAL_QUEUE             = 'ac_local';                                       # LOCAL meadow resource for AC jobs
  $SiteDefs::ENSEMBL_AC_LSF_QUEUE               = 'toolsgeneral';                                   # LSF queue for AC jobs, if running on farm
  $SiteDefs::ENSEMBL_AC_LSF_TIMEOUT             = undef;                                            # Max timelimit an AC job is allowed to run
  $SiteDefs::ENSEMBL_AC_ANALYSIS_CAPACITY       = 4;                                                # Number of jobs that can be run parallel in LSF in the queue

}

1;
