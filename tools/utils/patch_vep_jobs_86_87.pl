# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
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
    require SiteDefs; SiteDefs->import;
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

# changes
my $field_name_changes = {
  'gmaf'      => 'af',
  'maf_1kg'   => 'af_1kg',
  'maf_esp'   => 'af_esp',
  'maf_exac'  => 'af_exac'
};
my $field_value_changes = {
  'sift'      => {
    'both'      => 'b',
    'pred'      => 'p',
    'score'     => 's'
  },
  'polyphen'  => {
    'both'      => 'b',
    'pred'      => 'p',
    'score'     => 's'
  },
  'check_existing' => {
    'yes'       => 'no_allele',
    'allele'    => 'yes'
  }
};

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

my $input = '';
while ($input !~ m/^(y|n)$/i) {
  print sprintf "\nThis will update all the VEP jobs on %s\@%s:%s\nConfirm (y/n):", $db->{'database'}, $db->{'host'}, $db->{'port'};
  $input = <STDIN>;
}

close STDIN;

chomp $input;

die "Update aborted.\n" if $input =~ /n/i;

# Register db with rose api
ORM::EnsEMBL::Rose::DbConnection->register_database($db);

# Iterator for all VEP jobs
my $tickets_iterator = ORM::EnsEMBL::DB::Tools::Manager::Ticket->get_objects_iterator(
  'query'         => [ 'status' => {'ne' => 'Deleted'}, 'ticket_type_name' => 'VEP' ],
  'with_objects'  => [ 'job' ],
  'sort_by'       => 'created_at ASC',
);

# Any error?
if ($tickets_iterator->error) {
  print sprintf "ERROR: %s\n", $tickets_iterator->error;
  exit 1;
}

# For all tickets that have no validity left, mark them as deleted and remove all the related dirs from the file system
while (my $ticket = $tickets_iterator->next) {
  if (my ($job) = $ticket->job) { # each VEP ticket has only one job

    my $input_data  = $job->job_data->raw;
    my $changed     = 0;

    for (grep exists $input_data->{$_}, keys %$field_name_changes) {
      $input_data->{$field_name_changes->{$_}} = delete $input_data->{$_};
      $changed = 1;
    }

    for (grep exists $input_data->{$_}, keys %$field_value_changes) {
      $input_data->{$_} = $field_value_changes->{$_}{$input_data->{$_}} // $input_data->{$_};
      $changed = 1;
    }

    if ($changed) {
      print sprintf "INFO: Updating %s\n", $ticket->ticket_name;
      $job->job_data($input_data);
      $ticket->save('cascade' => 1) or print sprintf "WARNING: Ticket %s could not be updated.\n", $ticket->ticket_name;
    }

  } else {
    print sprintf "WARNING: Ticket %s has no linked job.\n", $ticket->ticket_name;
  }
}

print "INFO: DONE\n";

