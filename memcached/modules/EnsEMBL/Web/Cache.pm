
=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Cache;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);

use EnsEMBL::Web::Attributes;

use base qw(Cache::Memcached);

use fields qw(default_exptime ens_debug);

sub new {
  my $class     = shift;
  my $caller    = caller;
  my $memcached = $SiteDefs::ENSEMBL_MEMCACHED;

  return undef unless $memcached && %$memcached;

  my %args = (
    servers         => $memcached->{'servers'},
    debug           => $memcached->{'debug'},
    default_exptime => $memcached->{'default_exptime'},
    namespace       => $SiteDefs::ENSEMBL_BASE_URL,
    @_,
  );

  my $default_exptime = delete $args{'default_exptime'};
  my $ens_debug       = exists $args{'ens_debug'} ? delete $args{'ens_debug'} : $SiteDefs::ENSEMBL_DEBUG_CACHE || 0;

  my $self = $class->SUPER::new(\%args);

  $self->enable_compress(0) unless $args{'enable_compress'};

  $self->{'default_exptime'} = $default_exptime;
  $self->{'ens_debug'} = $ens_debug;

  return $self;
}

sub set {
  my ($self, $key, $value, $exptime) = @_;

  return unless $value;

  my $result = $self->SUPER::set(md5_hex($key), $value, $exptime);

  $self->_warn(sprintf 'MEMCACHED->set(%s): %s', $key, $result ? 'DONE' : 'FAIL');

  return $result;
}

sub set_raw {
  my ($self, $key, $value, $exptime) = @_;

  return unless $value;

  my $result = $self->SUPER::set($key, $value, $exptime);

  $self->_warn(sprintf 'MEMCACHED->set_raw(%s): %s', $key, $result ? 'DONE' : 'FAIL');

  return $result;
}

sub get {
  my ($self, $key) = @_;

  my $result = $self->SUPER::get(md5_hex($key));

  $self->_warn(sprintf 'MEMCACHED->get(%s): %s', $key, $result ? 'HIT' : 'MISS');

  return $result;
}

sub remove {
  my $self = shift;
  my $key  = shift;

  $self->_warn("MEMCACHED->delete($key)");

  return $self->SUPER::remove(md5_hex($key), @_);
}

sub delete {
  return shift->remove(@_);
}

sub version_check {
  my $self      = shift;
  my @hosts     = @{$self->{'buckets'}};
  my $versions  = {};
  my $errors    = {};

  foreach my $host (@hosts) {

    eval {
      my $sock = $self->sock_to_host($host);
      my $res  = ($self->_write_and_read($sock, "version\r\n") || '') =~ s/[\n|\r]//rg;

      if ($res) {
        $versions->{$res} = 1;
        warn "Memcached host $host - $res\n";
      } else {
        warn "Memcached host $host - connection error, ignoring\n";
      }
    };

    if ($@) {
      $errors->{$host} = $@;
    }
  }

  if (keys %$errors) {
    die(join '', map { "Error connecting memcached host $_:\nERROR: $errors->{$_}\n" } keys %$errors);
  }

  if (keys %$versions > 1) {
    die "All Memcached hosts are not of same version\n";
  }

  return 1;
}

sub _warn {
  my $self = shift;
  map warn(($_ =~ s/\R/<N>/gr)."\n"), @_ if $self->{'ens_debug'};
}

sub add_tags        :Deprecated('Memcached Tags are not supported anymore') {}
sub delete_by_tags  :Deprecated('Memcached Tags are not supported anymore') {}

1;
