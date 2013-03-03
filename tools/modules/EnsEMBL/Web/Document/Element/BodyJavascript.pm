package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;

sub init {
  my $self         = shift;
  my $species_defs = $self->species_defs;
  
  foreach my $root (reverse @{$species_defs->ENSEMBL_HTDOCS_DIRS}) {
    my $dir = "$root/components";

    if (-e $dir && -d $dir) {
      opendir DH, $dir;
      my @files = readdir DH;
      closedir DH;

      $self->add_source("/components/$_") for sort grep { /^\d/ && -f "$dir/$_" && /\.js$/ } @files;
    }
  }
}


1;


