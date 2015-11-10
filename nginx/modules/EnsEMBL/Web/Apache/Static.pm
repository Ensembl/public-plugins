package EnsEMBL::Web::Apache::Static;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use SiteDefs;
use EnsEMBL::Web::Cache;

our $SMEMD = EnsEMBL::Web::Cache->new(
  namespace => '', # nginx namespaces incompatible with perl namespaces
);

sub static_cache_hook {
  my ($uri,$content) = @_;

  return unless $SMEMD and $SMEMD->can('set_raw');
  my $key = "nginx-".md5_hex("$SiteDefs::ENSEMBL_STATIC_BASE_URL$uri");
  $SMEMD->set_raw($key,$content);
}

1;
