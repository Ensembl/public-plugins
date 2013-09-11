package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use JavaScript::Minifier;
use CSS::Minifier;

use EnsEMBL::Web::Tools::MethodMaker(copy => ['merge_all','_merge_all2']);

sub merge_all {
  my ($sd) = @_;
  $sd->{'_storage'}{'SOLR_JS_NAME'} = merge_solr_js($sd);
  $sd->{'_storage'}{'SOLR_CSS_NAME'} = merge_solr_css($sd);
  _merge_all2($sd);
}

sub merge_solr_js {
  my ($sd) = @_;

  my $dir = [split 'modules',__FILE__]->[0] . "htdocs";
  my ($contents) = get_contents('js',$dir,'solr');
  my $root_dir = $sd->ENSEMBL_SERVERROOT;
  my $compression_dir = "$root_dir/utils/compression/";
  my $filename = md5_hex($contents);
  my $minified = "$root_dir/htdocs/minified/$filename.js";
  my $tmp = "$minified.tmp";

  return $filename if(-e $minified);
  open(OUT,">$tmp") or die "Cannot open $tmp for writing";
  print OUT '(function($,window,document,undefined){'.$contents.'})(jQuery,this,document)';
  close OUT;
  system($sd->ENSEMBL_JAVA,"-jar","$compression_dir/compiler.jar",
         "--js",$tmp,"--js_output_file",$minified,
         "--compilation_level","SIMPLE_OPTIMIZATIONS",
         "--warning_level","QUIET");
  unlink $tmp;
  unless(-s $minified) {
    open(OUT,">$minified") or die "Cannot open $minified for writing";
    print OUT JavaScript::Minifier::minify(input => $contents);
    close OUT;
  }
  return $filename;
}

sub merge_solr_css {
  my ($sd) = @_;

  my $dir = [split 'modules',__FILE__]->[0] . "htdocs";
  my ($contents) = get_contents('css',$dir,'solr');
  my $root_dir = $sd->ENSEMBL_SERVERROOT;
  my $filename = md5_hex($contents);

  my $seqmark = $sd->colour('sequence_markup') || {};
  my %colours = (%{$sd->ENSEMBL_STYLE || {}}, map { $_ => $seqmark->{$_}{'default'} } keys %$seqmark);
  $colours{$_} =~ s/^([0-9A-F]{6})$/#$1/i for keys %colours;
  $contents =~ s/\[\[(\w+)\]\]/$colours{$1}||"\/* ARG MISSING DEFINITION $1 *\/"/eg; 
  my $minified = "$root_dir/htdocs/minified/$filename.css";
  unless(-s $minified) {
    open(OUT,">$minified") or die "Cannot open $minified for writing";
    print OUT CSS::Minifier::minify(input => $contents);
    close OUT;
  } 
  return $filename;
}

1;

