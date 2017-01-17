# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2017] EMBL-European Bioinformatics Institute
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

use strict;
use warnings;

use Cwd;
use File::Basename;
use File::Spec;

BEGIN {

  my @dirname   = File::Spec->splitdir(dirname(Cwd::realpath(__FILE__)));
  my $code_path = File::Spec->catdir(splice @dirname, 0, -3);

  # Load SiteDefs
  unshift @INC, File::Spec->catdir($code_path, qw(ensembl-webcode conf));
  eval {
    require SiteDefs;
  };
  if ($@) {
    print "ERROR: Can't use SiteDefs - $@\n";
    exit 1;
  }

  # Check if EnsEMBL::Tools exist in plugins
  if (!{@{$SiteDefs::ENSEMBL_PLUGINS}}->{'EnsEMBL::Tools'}) {
    print "ERROR: Tools plugin is not loaded. Please add it to the Plugins.pm file before running this script.\n";
    exit 1;
  }

  # Include all code dirs
  unshift @INC, reverse @{SiteDefs::ENSEMBL_LIB_DIRS};
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;
}

use ORM::EnsEMBL::Rose::DbConnection;
use ORM::EnsEMBL::DB::Tools::Manager::Ticket;
use EnsEMBL::Web::SpeciesDefs;
use EnsEMBL::Web::Utils::FileSystem qw(remove_empty_path);

# Dry run?
my $dry = !!grep(m/^\-?\-(n|dry)$/, @ARGV);
if ($dry) {
  print "INFO: Dry run only, not actually making any changes.\n";
}

# Limit
my $limit;
for (@ARGV) {
  if ($limit) {
    $limit = $_ if $_ =~ /^\d+$/;
    last;
  }
  if ($_ =~ /^\-?\-limit$/) {
    $limit = -1;
  }
}
if ($limit && $limit > 0) {
  print "INFO: Limit applied, only first $limit tickets will be deleted.\n";
} else {
  $limit = -1;
}

# Get db connection
my $sd  = EnsEMBL::Web::SpeciesDefs->new();
my $db  = {
  'database'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'},
  'host'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
  'port'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
  'username'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'USER'} || $sd->DATABASE_WRITE_USER,
  'password'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PASS'} || $sd->DATABASE_WRITE_PASS,
  'type'      => 'ticket',
  'domain'    => 'ensembl',
  'trackable' => 0
};

my $sub_limit = 1000;
my $counter   = 0;
my $validity  = $sd->ENSEMBL_TICKETS_VALIDITY;

print sprintf "INFO: Current time %s\n", scalar localtime;
print sprintf "INFO: Deleting tickets created before %s\n", scalar localtime(time - $validity);
print sprintf "INFO: Database %s\n", $db->{'database'};
print sprintf "INFO: Host %s:%s\n", $db->{'host'}, $db->{'port'};

# Register db with rose api
ORM::EnsEMBL::Rose::DbConnection->register_database($db);

while ($limit) {

  $sub_limit  = $limit > 0 ? [ $limit, $sub_limit ]->[ $limit > $sub_limit ] : $sub_limit;
  $limit      = $limit - $sub_limit if $limit > 0;

  print sprintf "INFO: Iteration %s: Fetching %s tickets\n", ++$counter, $sub_limit;

  # Fetch all non-user tickets that are not already marked as deleted limited by $sub_limit
  my $tickets_iterator = ORM::EnsEMBL::DB::Tools::Manager::Ticket->get_objects_iterator(
    'query'         => [ 'owner_type' => {'ne' => 'user'}, 'status' => {'ne' => 'Deleted'} ],
    'with_objects'  => [ 'job' ],
    'sort_by'       => 'created_at ASC',
    'multi_many_ok' => 1,
    'limit'         => $sub_limit, # this is to avoid loading all tickets in memory at once
#    'debug'         => 1,
  );

  # Any error?
  if ($tickets_iterator->error) {
    print sprintf "ERROR: %s\n", $tickets_iterator->error;
    exit 1;
  }

  # For all tickets that have no validity left, mark them as deleted and remove all the related dirs from the file system
  my $deleted = 0;
  while (my $ticket = $tickets_iterator->next) {
    if (!$ticket->calculate_life_left($validity)) {
      print sprintf "INFO: Deleting ticket %s\n", $ticket->ticket_name;
      eval {
        if ($dry || $ticket->mark_deleted) {
          for (grep $_->job_dir, $ticket->job) {
            my @dir = File::Spec->splitdir($_->job_dir);
            my $dir = File::Spec->catdir(splice @dir, 0, -1);
            print "INFO: Removing $dir\n";
            if (!$dry && -d $dir && !remove_empty_path($dir, { 'remove_contents' => 1, 'exclude' => [ $ticket->ticket_type_name ], 'no_exception' => 1 })) {
              print "WARNING: Could not remove ticket directory $dir\n";
            }
            last; # ticket dir removed, second attempt not required
          }
          $deleted++;
        } else {
          print sprintf "WARNING: Could not mark ticket %s as deleted.\n", $ticket->ticket_name;
        }
      };
      if ($@) { # some unknown error
        print sprintf "WARNING: Could not mark ticket %s as deleted.\n%s\n%s\n", $ticket->ticket_name, $@, "-" x 50;
      }
    }
  }

  # Any error?
  if ($tickets_iterator->error) {
    print sprintf "WARNING: %s\n", $tickets_iterator->error;
  }

  # If no ticket was deleted in this request, don't do any further requests
  if (!$deleted) {
    last;
  }

  if ($dry) {
    print "INFO: Only 1 iteration is done in DRY RUN mode.\n";
    last;
  }
}

print "INFO: DONE\n";
