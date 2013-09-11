package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;
use warnings;

use EnsEMBL::Web::Tools::MethodMaker(copy => ['init','_init2']);

sub init {
  my ($self) = @_;
  $self->_init2;
  $self->add_solr if $self->hub->type eq 'Search';
}

sub add_solr {
  my ($self) = @_;
  my $sd = $self->species_defs;
  if($self->debug) {
    $self->add_dir($_,'solr') for reverse @{$sd->ENSEMBL_HTDOCS_DIRS};
  } else {
    $self->add_source(sprintf("/%s/%s.js",$sd->ENSEMBL_JSCSS_TYPE,
                              $sd->SOLR_JS_NAME));
  }
}

sub add_dir {
  my ($self, $root, $subdir) = @_; 
  my $dir = "$root/$subdir";
  
  if (-e $dir && -d $dir) {
    opendir DH, $dir;
    my @files = readdir DH; 
    closedir DH; 
    
    foreach (sort { -d "$dir/$a" <=> -d "$dir/$b" || lc $a cmp lc $b } grep /\w/, @files) {
      if (-d "$dir/$_") {
        $self->add_dir($root, "$subdir/$_");
      } elsif (-f "$dir/$_" && /\.js$/) {
        $self->add_source("/$subdir/$_");
      }   
    }   
  }
}

1;

