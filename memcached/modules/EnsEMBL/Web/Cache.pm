package EnsEMBL::Web::Cache;

## This module overwrites several subroutines from Cache::Memcached
## to be able to track and monitor memcached statistics better
## this applies only when debug mode is on

use strict;

use Digest::MD5 qw(md5_hex);

use SiteDefs;

use base qw(Cache::Memcached);

use fields qw(default_exptime flags hm_stats);

no warnings;

sub new {
  my $class     = shift;
  my $caller    = caller;
  my $memcached = $SiteDefs::ENSEMBL_MEMCACHED;
  
  return undef unless $memcached && %$memcached;
  
  my %flags = map { $_ => 1 } @{$memcached->{'flags'} || [ 'PLUGGABLE_PATHS', 'TMP_IMAGES' ]};
     
  return undef if $caller->isa('EnsEMBL::Web::Apache::Handlers')        && !$flags{'PLUGGABLE_PATHS'};
  return undef if $caller->isa('EnsEMBL::Web::Apache::SSI')             && !$flags{'STATIC_PAGES_CONTENT'};
  return undef if $caller->isa('EnsEMBL::Web::DBSQL::UserDBConnection') && !$flags{'USER_DB_DATA'};
  return undef if $caller->isa('EnsEMBL::Web::DBSQL::WebDBConnection')  && !$flags{'WEBSITE_DB_DATA'};
  return undef if $caller->isa('EnsEMBL::Web::File::Driver::Memcached') && !$flags{'TMP_IMAGES'};
  return undef if $caller->isa('EnsEMBL::Web::Apache::Image')           && !$flags{'TMP_IMAGES'};
  return undef if $caller->isa('EnsEMBL::Web::Magic')                   && !$flags{'DYNAMIC_PAGES_CONTENT'};
  return undef if $caller->isa('EnsEMBL::Web::Configuration')           && !$flags{'ORDERED_TREE'};
  return undef if $caller->isa('EnsEMBL::Web::Object')                  && !$flags{'OBJECTS_COUNTS'};
  return undef if $caller->isa('EnsEMBL::Web::ImageConfig')             && !$flags{'IMAGE_CONFIG'};

  my %args = (
    servers         => $memcached->{'servers'},
    debug           => $memcached->{'debug'},
    hm_stats        => $memcached->{'hm_stats'},
    default_exptime => $memcached->{'default_exptime'},
    namespace       => $SiteDefs::ENSEMBL_BASE_URL,
    @_,
  );

  my $default_exptime = delete $args{'default_exptime'};

  my $self = $class->SUPER::new(\%args);
  
  $self->enable_compress(0) unless $args{'enable_compress'};

  $self->{'default_exptime'} = $default_exptime;
  $self->{'flags'}           = \%flags;
  $self->{'hm_stats'}        = delete $args{'hm_stats'};
  
  return $self;
}

sub flags :lvalue { $_[0]->{'flags'}; }

sub add_tags {
  my ($self, $key, @tags) = @_;

  _warn(sprintf 'MEMCACHED->add_tags(%s, %s)', $key, join ', ', @tags);
  
  $key = md5_hex($key);
  
  my $sock = $self->get_sock($key);
  
  foreach my $tag (@tags) {
    my $cmd = "tag_add $tag $self->{'namespace'}$key\r\n";
    my $res = $self->_write_and_read($sock, $cmd);
    
    return 0 unless $res eq "TAG_STORED\r\n";
  }

  return 1;
}


## delete_by_tags(@tags)
## deletes all and only items which have ALL tags specified
sub delete_by_tags {
  my $self = shift;
  my @tags = (@_, $self->{'namespace'});
  
  _warn(sprintf 'MEMCACHED->delete_by_tags(%s)', join ', ', @tags);
  
  my $cmd = sprintf "tags_delete %s\r\n", join ' ', @tags;
  my $items_deleted = 0;

  my @hosts = @{$self->{'buckets'}};
  
  foreach my $host (@hosts) {
    my $sock = $self->sock_to_host($host);
    my $res = $self->_write_and_read($sock, $cmd);
    
    if ($res =~ /^(\d+) ITEMS_DELETED/) {
      $items_deleted += $1;
    }
  }

  _warn("MEMCACHED: $items_deleted items deleted");
  
  return $items_deleted;
}

sub set {
  my ($self, $key, $value, $exptime, @tags) = @_;
  
  return unless $value;
  
  _warn("MEMCACHED->set($key)");
  
  my $result = $self->SUPER::set(md5_hex($key), $value, $exptime || $self->{'default_exptime'});
  
  $self->add_tags($key, $self->{'namespace'}, @tags) if $result;
  
  return $result;
}

sub get {
  my ($self, $key, @tags) = @_;

  _warn("MEMCACHED->get($key)");
  
  my $result = $self->SUPER::get(md5_hex($key));

  ## Hits & Misses statistics
  if ($self->{'hm_stats'} && @tags) {
    my $suffix = $result ? '::HITS' : '::MISSES';
    @tags = grep { $_ ne '' } @tags; 
    $self->incr("$_$suffix") for '', @tags;
    $self->incr("::TOTAL");
  }

  return $result;
}

sub incr {
  my ($self, $key) = @_;

  _warn("MEMCACHED->incr($key)");
  
  my $md5_key = md5_hex($key);
  
  $self->add_tags($key, $self->{'namespace'}, 'STATS') if !$self->SUPER::incr($md5_key) && $self->add($md5_key, '0000000001');
}

sub delete {
  my $self = shift;
  my $key  = shift;
  
  _warn("MEMCACHED->delete($key)");
  
  return $self->SUPER::remove(md5_hex($key), @_);
}

*remove = \&delete;

## Warn only if debug flags are on
sub _warn {
  warn @_ if $SiteDefs::ENSEMBL_DEBUG_FLAGS & $SiteDefs::ENSEMBL_DEBUG_MEMCACHED;
}

## Check if all memd servers are of the right version
## if any of them is not, return false
sub version_check {
  my $self    = shift;
  my $correct = 1;
  my @hosts   = @{$self->{'buckets'}};
  
  foreach my $host (@hosts) {
    my $sock = $self->sock_to_host($host);
    my $res  = $self->_write_and_read($sock, "version\r\n");
       $res  =~ s/[\n|\r]//g;
    
    if ($res && $res =~ /tags/) {
      warn "$host - $res\n";
    } elsif ($res) {
      warn "$host - $res, Incorrect version\n";
      $correct = 0;
    } else {
      warn "$host - connection error, ignoring\n";
    }
  }

  return $correct;
}

1;