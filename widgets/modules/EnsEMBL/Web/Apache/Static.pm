package EnsEMBL::Web::Apache::Static;

use strict;
use warnings;
use List::Util qw( any );

my @patterns_to_skip_caching = (
  qr/alphafold\/.*\.js$/ # javascript files in the alphafold folder
);

sub should_skip_caching {
  my $r = shift;
  my $uri = $r->uri;

  return any { $uri =~ $_ } @patterns_to_skip_caching;
}


1;
