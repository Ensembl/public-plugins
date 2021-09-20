package EnsEMBL::Web::Apache::Static;

use strict;
use warnings;

sub add_caching_headers {
  warn "I AM IN ADD CACHING PLUGINS";
  my $r = shift;
  my $uri = $r->uri;

  if (should_skip_caching($uri)) {
    $r->headers_out->set('Cache-Control'  => 'no-store, max-age=0');
  } else {
    # default behaviour
    my $thirty_days = 60 * 60 * 24 * 30;
    $r->headers_out->set('Cache-Control'  => 'max-age=' . $thirty_days);
    $r->headers_out->set('Expires'        => HTTP::Date::time2str(time + $thirty_days));
  }
}

sub should_skip_caching {
  my $uri = shift;
  my @patterns = (
    qr/alphafold\/.*\.js$/ # javascript files in the alphafold folder
  );

  my $bool;
  foreach my $pattern (@patterns) {
    if ($uri =~ /$pattern/) {
      $bool = 1;
    }
  }

  return $bool;
}

1;
