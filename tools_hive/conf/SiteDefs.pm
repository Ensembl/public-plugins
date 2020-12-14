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

package EnsEMBL::Tools_hive::SiteDefs;

### tools_hive plugin is a backend for running the ensembl tools jobs (BLAST, BLAT, VEP etc) using ensembl-hive.
### With this plugin, the jobs that are submitted by the website (via the tools plugin) are saved in the
### ENSEMBL_WEB_HIVE db and another process called 'beekeeper' (that could possibly be running on a different
### machine) continually looks at that database, runs the newly submitted jobs on LSF farm or on
### the local machine (LOCAL) where this process itself is running.

use strict;
use warnings;

sub validation {
  return {
    'type'      => 'functionality',
    'after'     => [qw(EnsEMBL::Tools)],
    'requires'  => [qw(EnsEMBL::Tools)]
  };
}

sub update_conf {

  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER       = { 
                                                    'Blast'             => 'Hive',
                                                    'VEP'               => 'Hive',
                                                    'AssemblyConverter' => 'Hive',
                                                    'IDMapper'          => 'Hive',
                                                    'FileChameleon'     => 'Hive',
                                                    'AlleleFrequency'   => 'Hive',
                                                    'VcftoPed'          => 'Hive',
                                                    'DataSlicer'        => 'Hive',
                                                    'VariationPattern'  => 'Hive',
                                                    'LD'                => 'Hive',
                                                    'VR'                => 'Hive',
                                                    'Postgap'           => 'Hive',
                                                  };                                                # Overriding tools plugin variable
  $SiteDefs::ENSEMBL_HIVE_HOSTS                 = [];                                               # For LOCAL, the machine that runs the beekeeper unless it's same as the web server
                                                                                                    # For LSF, list of hosts corresponding to the queues for all jobs plus the machine where
                                                                                                    # beekeeper is running unless it's same as the web server
                                                                                                    # Leave it blank if code is located on a shared disk to share between the web server and the machine(s)
                                                                                                    # running beekeeper
  $SiteDefs::ENSEMBL_HIVE_HOSTS_CODE_LOCATION   = $SiteDefs::ENSEMBL_SERVERROOT;                    # path from where hive hosts can access ensembl code (same as web root for jobs running on local machine)
  $SiteDefs::ENSEMBL_TOOLS_PIPELINE_PACKAGE     = 'EnsEMBL::Web::PipeConfig::Tools_conf';           # package read by init_pipeline.pl script from hive to create the hive database
  $SiteDefs::EHIVE_ROOT_DIR                     = $SiteDefs::ENSEMBL_SERVERROOT.'/ensembl-hive/';   # location from there hive scripts on the web server (not the hive hosts) can access the hive API
  $SiteDefs::ENSEMBL_SETENV->{'EHIVE_ROOT_DIR'} = 'EHIVE_ROOT_DIR';                                 # Add to ENV too


  # Add ensembl-hive to libs
  unshift @{$SiteDefs::ENSEMBL_API_LIBS}, "$SiteDefs::ENSEMBL_SERVERROOT/ensembl-hive/modules";

  @SiteDefs::ENSEMBL_TOOLS_LIB_DIRS = qw(
    ensembl
    ensembl-hive
    ensembl-io
    ensembl-variation
    ensembl-funcgen
    ensembl-tools
    ensembl-webcode
    ensembl-vep
    public-plugins
    ebi-plugins
    VEP_plugins
  );

  # BLAST configs
  $SiteDefs::ENSEMBL_BLAST_RUN_LOCAL            = 1;                                                # Flag if on, will run blast jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_BLAST_QUEUE                = 'highpri';                                        # LSF or LOCAL queue for blast jobs
  $SiteDefs::ENSEMBL_BLAST_LSF_TIMEOUT          = undef;                                            # Max timelimit a blast job is allowed to run on LSF
  $SiteDefs::ENSEMBL_BLAST_MEMORY_USAGE         = 8;                                                # Memory in GBs required for Blast jobs
  $SiteDefs::ENSEMBL_BLAST_ANALYSIS_CAPACITY    = 500;                                              # Number of jobs that can be run parallel in the blast queue (LSF or LOCAL)
  $SiteDefs::ENSEMBL_NCBIBLAST_BIN_PATH         = '/path/to/ncbi-blast/bin';                        # path to blast executables on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_NCBIBLAST_DATA_PATH        = "/path/to/genes";                                 # path for the blast index files (other than DNA) on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_NCBIBLAST_DATA_PATH_DNA    = "/path/to/blast/dna";                             # path for the blast DNA index files on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_REPEATMASK_BIN_PATH        = '/path/to/RepeatMasker';                          # path to RepeatMasker executable on the  LSF host (or local machine if job running locally)

  # BLAT configs
  $SiteDefs::ENSEMBL_BLAT_RUN_LOCAL             = 1;                                                # Flag if on, will run blat jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_BLAT_QUEUE                 = 'highpri';                                        # LSF or LOCAL queue for blat jobs
  $SiteDefs::ENSEMBL_BLAT_LSF_TIMEOUT           = undef;                                            # Max timelimit a blat job is allowed to run on LSF
  $SiteDefs::ENSEMBL_BLAT_MEMORY_USAGE          = undef;                                            # Memory in GBs required for Blat jobs (undef for default LSF limit)
  $SiteDefs::ENSEMBL_BLAT_ANALYSIS_CAPACITY     = 500;                                              # Number of jobs that can be run parallel in the blat queue (LSF or LOCAL)
  $SiteDefs::ENSEMBL_BLAT_TWOBIT_DIR            = "/path/to/blat/twobit";                           # location where blat twobit files are located on LSF node (or local machine if job running locally)
  $SiteDefs::ENSEMBL_BLAT_QUERY_COMMAND         = '/path/to/command [SPECIES].[ASSEMBLY]';          # optional command line that returns server:port for BLAT server for a given species and assembly

  # VEP configs
  $SiteDefs::ENSEMBL_VEP_RUN_LOCAL              = 1;                                                # Flag if on, will run VEP jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_VEP_QUEUE                  = 'highpri';                                        # LSF or LOCAL queue for VEP jobs
  $SiteDefs::ENSEMBL_VEP_LSF_TIMEOUT            = '3:00';                                           # Max timelimit a VEP job is allowed to run on LSF
  $SiteDefs::ENSEMBL_VEP_MEMORY_USAGE           = 8;                                                # Memory in GBs required for VEP jobs
  $SiteDefs::ENSEMBL_VEP_ANALYSIS_CAPACITY      = 500;                                              # Number of jobs that can be run parallel in the VEP queue (LSF or LOCAL)
  $SiteDefs::ENSEMBL_VEP_CACHE_DIR              = "/path/to/vep/cache";                             # path to vep cache files
  $SiteDefs::ENSEMBL_VEP_FASTA_DIR              = "/path/to/fasta/files";                           # path to bgzipped & indexed FASTA files for use by VEP
  $SiteDefs::ENSEMBL_VEP_SCRIPT_DEFAULT_OPTIONS = {                                                 # Default options for command line vep script (keys with value undef get ignored)
    'host'        => undef,                                                                         # Database host (defaults to ensembldb.ensembl.org)
    'user'        => undef,                                                                         # Defaults to 'anonymous'
    'password'    => undef,                                                                         # Not used by default
    'port'        => undef,                                                                         # Defaults to 5306
    'fork'        => 4,                                                                             # Enable forking, using 4 forks
  };

  $SiteDefs::ENSEMBL_VEP_PLUGIN_DATA_DIR        = "/path/to/vep/plugin_data";                       # path to vep plugin data files on the LSF host (or local machine if job running locally)
  $SiteDefs::ENSEMBL_VEP_PLUGIN_DIR             = "VEP_plugins";                                    # path to vep plugin code (if does not start with '/', it's treated relative to ENSEMBL_HIVE_HOSTS_CODE_LOCATION)

  push @{$SiteDefs::ENSEMBL_VEP_PLUGIN_CONFIG_FILES}, $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/tools_hive/conf/vep_plugins_hive_config.txt';
                                                                                                    # add extra hive specific configs required to run vep plugins
  # LD configs
  $SiteDefs::ENSEMBL_LD_RUN_LOCAL              = 1;                                                # Flag if on, will run LD jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_LD_QUEUE                  = 'highpri';                                        # LSF or LOCAL queue for LD jobs
  $SiteDefs::ENSEMBL_LD_LSF_TIMEOUT            = undef;                                            # Max timelimit a LD job is allowed to run on LSF
  $SiteDefs::ENSEMBL_LD_ANALYSIS_CAPACITY      = 500;                                              # Number of jobs that can be run parallel in the LD queue (LSF or LOCAL)

  # Variant Recoder configs
  $SiteDefs::ENSEMBL_VR_RUN_LOCAL              = 1;
  $SiteDefs::ENSEMBL_VR_QUEUE                  = 'highpri';
  $SiteDefs::ENSEMBL_VR_LSF_TIMEOUT            = undef;
  $SiteDefs::ENSEMBL_VR_ANALYSIS_CAPACITY      = 500;
  $SiteDefs::ENSEMBL_VR_SCRIPT_DEFAULT_OPTIONS = {
    'host'        => 'mysql-ens-web-dev-01',
    'user'        => 'ensro',
    'password'    => undef,
    'port'        => '4536'
  };

  # Assembly Converter configs
  $SiteDefs::ENSEMBL_AC_RUN_LOCAL               = 1;                                                # Flag if on, will run AC jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_AC_QUEUE                   = 'highpri';                                        # LSF or LOCAL queue for AC jobs
  $SiteDefs::ENSEMBL_AC_LSF_TIMEOUT             = undef;                                            # Max timelimit an AC job is allowed to run on LSF
  $SiteDefs::ENSEMBL_AC_ANALYSIS_CAPACITY       = 500;                                              # Number of jobs that can be run parallel in the queue (LSF or LOCAL)
  $SiteDefs::ENSEMBL_CHAIN_FILE_DIR             = '/path/to/assembly_converter/chain_files';        # path to chain files as required by assembly converter
  $SiteDefs::ASSEMBLY_CONVERTER_BIN_PATH        = '/path/to/CrossMap.py';                           # path to CrossMap
  $SiteDefs::WIGTOBIGWIG_BIN_PATH               = '/path/to/wigToBigWig';                           # path to wigToBigWig (required by CrossMap)
  $SiteDefs::BIGWIGTOWIG_BIN_PATH               = '/path/to/bigWigToWig';                           # path to bigWigToWig (needed to RunnableDB/AssemblyConverter)

  # ID History converter configs
  $SiteDefs::ENSEMBL_IDM_RUN_LOCAL              = 1;                                                # Flag if on, will run ID mapper jobs on LOCAL meadow
  $SiteDefs::ENSEMBL_IDM_QUEUE                  = 'highpri';                                        # LSF or LOCAL queue for ID mapper jobs
  $SiteDefs::ENSEMBL_IDM_LSF_TIMEOUT            = undef;                                            # Max timelimit an ID mapper job is allowed to run on LSF
  $SiteDefs::ENSEMBL_IDM_MEMORY_USAGE           = 6;                                                # Memory in GBs required for IDMapper jobs
  $SiteDefs::ENSEMBL_IDM_ANALYSIS_CAPACITY      = 500;                                              # Number of jobs that can be run parallel in the queue (LSF or LOCAL)
  $SiteDefs::IDMAPPER_SCRIPT                    = 'ensembl-tools/scripts/id_history_converter/IDmapper.pl';
                                                                                                    # Path to ID History converter script

  # File Chameleon configs
  $SiteDefs::ENSEMBL_FC_RUN_LOCAL              = 1;
  $SiteDefs::ENSEMBL_FC_QUEUE                  = 'highpri';
  $SiteDefs::ENSEMBL_FC_LSF_TIMEOUT            = undef;                                            
  $SiteDefs::ENSEMBL_FC_ANALYSIS_CAPACITY      = 500;

  # Allele Frequency configs
  $SiteDefs::ENSEMBL_AF_RUN_LOCAL              = 1;
  $SiteDefs::ENSEMBL_AF_QUEUE                  = 'highpri';
  $SiteDefs::ENSEMBL_AF_ANALYSIS_CAPACITY      = 500;

  # VCF to PED configs
  $SiteDefs::ENSEMBL_VP_RUN_LOCAL              = 1;
  $SiteDefs::ENSEMBL_VP_QUEUE                  = 'highpri';
  $SiteDefs::ENSEMBL_VP_ANALYSIS_CAPACITY      = 500;
  $SiteDefs::ENSEMBL_VP_MEMORY_USAGE           = 6;

  # Data Slicer configs
  $SiteDefs::ENSEMBL_DS_RUN_LOCAL              = 1;
  $SiteDefs::ENSEMBL_DS_QUEUE                  = 'highpri';
  $SiteDefs::ENSEMBL_DS_ANALYSIS_CAPACITY      = 500;

  # Variation pattern finder configs
  $SiteDefs::ENSEMBL_VPF_RUN_LOCAL              = 1;
  $SiteDefs::ENSEMBL_VPF_QUEUE                  = 'highpri';
  $SiteDefs::ENSEMBL_VPF_ANALYSIS_CAPACITY      = 500;

  # Postgap configs
  $SiteDefs::ENSEMBL_POSTGAP_DATA              = "/path/to/postgap/databases"; 
  $SiteDefs::POSTGAP_HDF5_DATA                 = "/path/to/postgap/GTEx.V6.88_38.cis.eqtls.h5";
  $SiteDefs::POSTGAP_SQLITE_DATA               = "/path/to/postgap/GTEx.V6.88_38.cis.eqtls.h5.sqlite3";
  $SiteDefs::ENSEMBL_PG_RUN_LOCAL              = 1;
  $SiteDefs::ENSEMBL_PG_QUEUE                  = 'long';
  $SiteDefs::ENSEMBL_PG_ANALYSIS_CAPACITY      = 3;

}

1;
