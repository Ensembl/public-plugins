#!/usr/local/bin/perl
###############################################################################
#   
#   Name:        EnsEMBL::Web::Tools::DHTMLmerge
#    
#   Description: Populates templates for static content.
#                Run at server startup
#
###############################################################################

package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;

use Digest::MD5 qw(md5_hex);
use JavaScript::Minifier;

use EnsEMBL::Web::Tools::MethodMaker(copy => [ 'merge_all', '_merge_all' ]);

sub merge_all {
  my $species_defs = shift;
  $species_defs->{'_storage'}{'GENOVERSE_JS_NAME'} = merge_genoverse($species_defs);
  _merge_all($species_defs);
}

# Create a separate genoverse file
sub merge_genoverse {
  my $species_defs    = shift;
  my $dir             = [split 'modules', __FILE__]->[0] . 'htdocs';
  my ($contents)      = get_contents('js', $dir, 'genoverse');
  my $root_dir        = $species_defs->ENSEMBL_SERVERROOT;
  my $compression_dir = "$root_dir/utils/compression/";
  my $filename        = md5_hex($contents);
  my $minified        = "$root_dir/htdocs/minified/$filename.js";
  my $tmp             = "$minified.tmp";
  
  if (!-e $minified) {
    open O, ">$tmp" or die "can't open $tmp for writing";
    printf O '(function($,window,document,undefined){%s})(jQuery,this,document)', $contents;
    close O;
   
    system $species_defs->ENSEMBL_JAVA, '-jar', "$compression_dir/compiler.jar", '--js', $tmp, '--js_output_file', $minified, '--compilation_level', 'SIMPLE_OPTIMIZATIONS', '--warning_level', 'QUIET';
    
    unlink $tmp;
    
    if (!-s $minified) {
      open  O, ">$minified" or die "can't open $minified for writing";
      print O JavaScript::Minifier::minify(input => $contents);
      close O;
    }
  }
  
  return $filename;
}

1;
