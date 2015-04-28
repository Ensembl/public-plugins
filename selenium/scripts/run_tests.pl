# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/usr/local/bin/perl

### Wrapper script for selenium tests. 
### Takes two JSON configuration files:
### - configure connection and select which tests are run in a particular batch
### - configure species to test (optional)

### The purpose of the latter file is to remove dependency on the web code.
### Instead, a helper script is used to dump some useful parts of the
### web configuration, which should then be eyeballed to ensure it looks OK.

use strict;

use FindBin qw($Bin);
use Getopt::Long;
use LWP::UserAgent;
use JSON qw(from_json);

use vars qw( $SERVERROOT );

BEGIN {
  $SERVERROOT = "$Bin/../../..";
  unshift @INC,"$SERVERROOT/../public-plugins/selenium/modules";  
  unshift @INC, "$SERVERROOT/conf";
  eval{ require SiteDefs };
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;    
}

my ($config, $species);

GetOptions(
  'config=s'  => \$config,
  'species=s' => \$species,
);

die 'Please provide a configuration file!' unless $config;

my $CONF    = from_json($config)  || {};
my $SPECIES = from_json($species) || {};

## Validate main configuration
unless ($CONF->{'host'}) {
  die "You must specify the selenium host, e.g. ???";
}

unless ($CONF->{'url'} && $CONF->{'url'} =~ /^http/) {
  die "You must specify a url to test against, eg. http://www.ensembl.org";
}

unless ($CONF->{'modules'} && scalar(@{$CONF->{'modules'}||[]})) {
  die "You must specify at least one test module, eg. ['Generic']";
}

unless ($CONF->{'modules'}[0]{'tests'} && scalar(@{$CONF->{'modules'}[0]{'tests'}||[]})) {
  die "You must specify at least one test method, eg. ['homepage']";
}

$SPECIES = {'none'} unless keys %$SPECIES;

my $browser = $CONF->{'browser'}  || 'firefox';
my $port    = $CONF->{'port'}     || '4444';
my $timeout = $CONF->{'timeout'}  || 50000;
my $verbose = $CONF->{'verbose'}  || 0;

# check to see if the selenium server is online(URL returns OK if server is online).
my $ua = LWP::UserAgent->new(keep_alive => 5, env_proxy => 1);
$ua->timeout(10);
my $response = $ua->get("http://$host:$port/selenium-server/driver/?cmd=testComplete");
if($response->content ne 'OK') { 
  print "\nSelenium Server is offline or IP Address is wrong !!!!\n";
  exit;
}

# hack: collect errors so that we can check for selenium failures
our @errors;
$SIG{'__DIE__'} = sub { push(@errors, $_[0]) };

## Basic config for test modules
my $test_config = {
                    url     => $CONF->{'url'},
                    host    => $CONF->{'host'},
                    port    => $port,
                    browser => $browser,
                    conf    => {
                                timeout => $timeout,
                                },
                    verbose => $verbose,  
                  };

## Run any non-species-specific tests first 
foreach my $module (@{$CONF->{'non_species'}{'modules'}}) {
  foreach my $test_set (@{$CONF->{'non_species'}{'modules'}{$module}{'tests'}) {
    run_test($module, $test_config, $test_set);    
  }
}

## Loop through the relevant tests
foreach (sort keys %$SPECIES) {
  foreach my $module (@{$CONF->{'species'}{'modules'}}) {
    foreach my $test_set (@{$CONF->{'species'}{'modules'}{$module}{'tests'}) {
      $test_config->{'species'} = $species;
      run_test($module, $test_config, $test_set);    
    }
  }
}

sub run_test {
  my ($module, $config, $tests) = @_;

  ## Try to use the package
  my $package = "EnsEMBL::Selenium::Test::$module";
  eval("use $package");
  if ($@) {
    push @errors, "TEST FAILED: Couldn't use $package\n$@";
    return;
  }
  my @test_names = keys @{$tests||[]};
  unless (@test_names) {
    push @errors, "TEST FAILED: No methods specified for test module $package";
    return;
  }

  my $object = $package->new($config);

  ## Run the tests
  foreach my $name (@test_names) {
    my $method = 'test_'.$name;
    my $error = $object->$method($tests->{$name});
    if ($error) {
      push @errors, $error;
    }
  }
}

exit;

