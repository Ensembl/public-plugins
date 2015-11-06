package EnsEMBL::Web::Apache::Static;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use SiteDefs;
use EnsEMBL::Web::Cache;

our $MEMD = EnsEMBL::Web::Cache->new(
  namespace => $SiteDefs::ENSEMBL_STATIC_BASE_URL
);

sub static_cache_hook {
  my ($uri,$content) = @_;

  return unless $MEMD and $MEMD->can('set_raw');
  my $key = "nginx-".md5_hex("$SiteDefs::ENSEMBL_STATIC_BASE_URL$uri");
  $MEMD->set_raw($key,$content);
}

1;
