package EnsEMBL::Memcached::SiteDefs;
use strict;

sub update_conf {
  $SiteDefs::ENSEMBL_MEMCACHED = {
    servers => [ qw(127.0.0.1:11311) ],
    flags   => [ qw(
      PLUGGABLE_PATHS
      STATIC_PAGES_CONTENT
      WEBSITE_DB_DATA
      DYNAMIC_PAGES_CONTENT
      TMP_IMAGES
      ORDERED_TREE
      OBJECTS_COUNTS
      IMAGE_CONFIG
    ) ],

    ## This setting switches cpan Cache::Memcached debug option,
    ## ... which is a bit useless
    debug   => 0,

    ## Website HITS and MISSES statistics for major items
    ## slows down the website!
    hm_stats => 0,
  };
  
  ## Use flags to enable what you would like to cache:
  ## PLUGGABLE_PATHS       - paths to pluggable scripts and static files
  ## STATIC_PAGES_CONTENT  - .html pages content, any pages which SendDecPafe handler is responsible for
  ## WEBSITE_DB_DATA       - website db data queries results
  ## USER_DB_DATA	         - user and group db data queries results (records, etc.)
  ## DYNAMIC_PAGES_CONTENT - all dynamic ajax responses
  ## TMP_IMAGES	           - temporary images (the one you see actual genomic data on) and their imagemaps
  ## ORDERED_TREE          - navigation tree
  ## OBJECTS_COUNTS        - defferent counts for objects like gene, transcript, location, etc...
  ## IMAGE_CONFIG          - Image configurations

  ## Use this to switch on ensemble caching debug messages:
  ## $SiteDefs::ENSEMBL_DEBUG_FLAGS |= $SiteDefs::ENSEMBL_DEBUG_MEMCACHED;

}

1;
