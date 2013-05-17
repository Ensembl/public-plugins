package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;

use EnsEMBL::Web::Tools::MethodMaker(copy => [ 'init', '_init' ]);

sub init {
  my $self = shift;
  $self->_init;
  $self->add_genoverse if grep $_->[2] eq 'genoverse', @{$self->hub->components};
}

sub add_genoverse {
  my $self         = shift;
  my $species_defs = $self->species_defs;
  
  if ($self->debug) {
    $self->add_dir($_, 'genoverse') for reverse @{$species_defs->ENSEMBL_HTDOCS_DIRS};
  } else {
    $self->add_source(sprintf '/%s/%s.js', $species_defs->ENSEMBL_JSCSS_TYPE, $species_defs->GENOVERSE_JS_NAME);
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


