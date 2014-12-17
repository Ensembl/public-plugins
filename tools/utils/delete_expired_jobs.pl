# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
if ($limit > 0) {
  print "INFO: Limit applied, only first $limit tickets will be deleted.\n";
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

print sprintf "INFO: Deleting tickets older than %s seconds from %s on %s:%s\n", $sd->ENSEMBL_TICKETS_VALIDITY, $db->{'database'}, $db->{'host'}, $db->{'port'};

# Register db with rose api
ORM::EnsEMBL::Rose::DbConnection->register_database($db);

# Fetch all non-user tickets that are not already marked as deleted
my $tickets_iterator = ORM::EnsEMBL::DB::Tools::Manager::Ticket->get_objects_iterator(
  'query'         => [ 'owner_type' => {'ne' => 'user'}, 'status' => {'ne' => 'Deleted'} ],
  'with_objects'  => [ 'job', 'job.result', 'job.job_message' ],
  'sort_by'       => 'created_at ASC',
  'multi_many_ok' => 1, $limit > 0 ? (
  'limit'         => $limit ) : (),
#  'debug'         => 1,
);

# Any error?
if ($tickets_iterator->error) {
  print sprintf "ERROR: %s\n", $tickets_iterator->error;
  exit 1;
}

# For all tickets that have no validity left, mark them as deleted and remove all the related dirs from the file system
while (my $ticket = $tickets_iterator->next) {
  if (!$ticket->calculate_life_left($sd->ENSEMBL_TICKETS_VALIDITY)) {
    print sprintf "INFO: Deleting ticket %s\n", $ticket->ticket_name;
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
    } else {
      print sprintf "WARNING: Could not mark ticket %s as deleted.\n", $ticket->ticket_name;
    }
  }
}

print "INFO: DONE\n";
