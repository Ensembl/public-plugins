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

package EnsEMBL::Linuxbrew::SiteDefs;

use strict;
use warnings;

use Cwd qw(abs_path);
use List::MoreUtils qw(uniq);

sub update_conf {


  ## Apache-writeable locations
  $SiteDefs::ENSEMBL_SYS_DIR                = defer { "$SiteDefs::ENSEMBL_TMP_DIR/server" };
  $SiteDefs::ENSEMBL_ROBOTS_TXT_DIR         = defer { $SiteDefs::ENSEMBL_SYS_DIR };
  $SiteDefs::ENSEMBL_MINIFIED_FILES_PATH    = defer { "$SiteDefs::ENSEMBL_SYS_DIR/minified" };
  $SiteDefs::ENSEMBL_OPENSEARCH_PATH        = defer { "$SiteDefs::ENSEMBL_SYS_DIR/opensearch" };
  $SiteDefs::GOOGLE_SITEMAPS_PATH           = defer { "$SiteDefs::ENSEMBL_SYS_DIR/sitemaps" };


  $SiteDefs::SHARED_SOFTWARE_BIN_PATH       = defer { join ':', uniq($SiteDefs::SHARED_SOFTWARE_PATH.'/linuxbrew/bin', split(':', $ENV{'PATH'} || ())) };
  $SiteDefs::ENSEMBL_SETENV->{'PATH'}       = 'SHARED_SOFTWARE_BIN_PATH';

  $SiteDefs::APACHE_BIN                     = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/apache/httpd' };
  $SiteDefs::APACHE_DIR                     = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/apache/' };
  $SiteDefs::ENSEMBL_NGINX_EXE              = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/nginx' };
  $SiteDefs::BIOPERL_DIR                    = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/bioperl/' };
  $SiteDefs::VCFTOOLS_PERL_LIB              = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/vcftools_perl_lib/' };
  $SiteDefs::TABIX                          = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/tabix' };
  $SiteDefs::SAMTOOLS                       = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/samtools' };
  $SiteDefs::BGZIP                          = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/bgzip' };
  $SiteDefs::HTSLIB_DIR                     = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/htslib' };
  $SiteDefs::R2R_BIN                        = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/r2r' };
  $SiteDefs::ENSEMBL_JAVA                   = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/java' };
  $SiteDefs::ENSEMBL_EMBOSS_PATH            = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/emboss' };   #AlignView
  $SiteDefs::ENSEMBL_WISE2_PATH             = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/genewise' }; #AlignView
  $SiteDefs::THOUSANDG_TOOLS_DIR            = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/1000G-tools' }; #location of all 1000G tools runnable and scripts 

  $SiteDefs::GRAPHIC_TTF_PATH               = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/fonts/' };
  
  $SiteDefs::ENSEMBL_NCBIBLAST_BIN_PATH     = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/ncbi-blast/' };
  $SiteDefs::ENSEMBL_REPEATMASK_BIN_PATH    = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/RepeatMasker' };
  $SiteDefs::ENSEMBL_BLAT_BIN_PATH          = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/gfClient' };
  $SiteDefs::ASSEMBLY_CONVERTER_BIN_PATH    = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/CrossMap.py' };
  $SiteDefs::WIGTOBIGWIG_BIN_PATH        = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/wigToBigWig' };
  $SiteDefs::BIGWIGTOWIG_BIN_PATH        = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/bigWigToWig' };
  $SiteDefs::FILE_CHAMELEON_BIN_PATH        = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/FileChameleon/bin/format_transcriber.pl' };
  $SiteDefs::ALLELE_FREQUENCY_BIN_PATH      = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/1000G-tools/allelefrequency/calculate_allele_frq_from_vcf.pl' };
  $SiteDefs::VCF_PED_BIN_PATH               = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/1000G-tools/vcftoped/vcftoped.pl' };
  $SiteDefs::DATA_SLICER_BIN_PATH           = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/1000G-tools/dataslicer/dataslicer.pl' };
  $SiteDefs::VARIATION_PATTERN_BIN_PATH     = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/1000G-tools/variantpattern/variant_pattern_finder.pl' };    
}

1;
