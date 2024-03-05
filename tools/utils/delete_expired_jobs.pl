#! /usr/bin/env perl

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

use Getopt::Long;
use Storable qw(retrieve);
use Fcntl qw(:flock);
use FindBin qw($Bin);
use List::Util qw(shuffle);

# Path setup
my ($CONF,$SD,$PD);
my ($force,$dry,$limit,$super);
BEGIN {
  ($force,$dry,$limit,$super) = (0,0,-1,0);
  GetOptions(
    "n|dry" => \$dry,
    "f|force" => \$force,
    "limit=s" => \$limit,
    "s|super" => \$super,
  );

  my $path = $ARGV[0] || 'config.sconf';
  unless($path =~ m!^/!) {
    my $file = $path;
    my @path = split('/',$Bin);
    while(@path) {
      $path = join('/',@path,$file);
      last if -e $path;
      pop @path;
    }
    die "Cannot find '$file'\n" unless @path;
  }

  warn "Using $path\n";
  $CONF = retrieve($path);
  $SD = $CONF->{'SiteDefs'};
  $PD = $CONF->{'packed'};
  unshift @INC,reverse @{$SD->{'ENSEMBL_LIB_DIRS'}};
}

# Cronjob hygiene
my $MIN_AGE = 0;
my $LOCK_FILE =  "$SD->{'ENSEMBL_TMP_DIR'}/tooks-expiry.lock";
my $STAMP_FILE = "$SD->{'ENSEMBL_TMP_DIR'}/tools-expiry.stamp";

alarm 86400;
unless($force) {
  open(LOCKFILE,'>>',$LOCK_FILE) or die "Cannot open lockfile '$LOCK_FILE': $!";
  unless(flock(LOCKFILE,LOCK_EX|LOCK_NB)) {
    warn "Already running";
    exit 0;
  }
}
if(not $dry and -e $STAMP_FILE and time-((stat $STAMP_FILE)[9]) < $MIN_AGE) {
  print "Not running, too soon";
  exit 0;
}
qx(touch $STAMP_FILE);
warn "Starting run";

# Database connection
use ORM::EnsEMBL::Rose::DbConnection;
use ORM::EnsEMBL::DB::Tools::Manager::Ticket;
use ORM::EnsEMBL::DB::Tools::Manager::Job;
use EnsEMBL::Web::Utils::FileSystem qw(remove_empty_path);

my $validity  = $SD->{'ENSEMBL_TICKETS_VALIDITY'};

warn "Limiting to $limit tickets\n" unless $limit == -1;

my $db_pd = $PD->{'MULTI'}{'databases'}{'DATABASE_WEB_TOOLS'};
my $db  = {
  'database'  =>  $db_pd->{'NAME'},
  'host'      =>  $db_pd->{'HOST'},
  'port'      =>  $db_pd->{'PORT'},
  'username'  =>  $db_pd->{'USER'} || $SD->{'DATABASE_WRITE_USER'},
  'password'  =>  $db_pd->{'PASS'} || $SD->{'DATABASE_WRITE_PASS'},
  'type'      => 'ticket',
  'domain'    => 'ensembl',
  'trackable' => 0
};
warn "using ".join(':',map { $db_pd->{$_} } qw(NAME HOST PORT USER))."\n";
ORM::EnsEMBL::Rose::DbConnection->register_database($db);

sub job_iterator {
  my ($ticket) = @_;

  my $iter = 
    ORM::EnsEMBL::DB::Tools::Manager::Job->get_objects_iterator(
      'query'         => [ 'ticket_id' => $ticket->ticket_id ],
    );
  if ($iter->error) {
    warn "ERROR: ".($iter->error)."\n";
    exit 1;
  }
  return $iter;
}

# Deleting mechanics
sub we_can_delete {
  my ($ticket) = @_;

  my $job_iter = job_iterator($ticket);
  my $any_dirs = 0;
  while(my $job = $job_iter->next) {
    $any_dirs = 1 if -e $job->job_dir;
  }
  unless($any_dirs) {
    warn "cannot delete, cannot find any job directories\n";
    return 0;
  }
  return 1;
}

sub delete_path {
  my ($ticket,$path) = @_;

  if($dry) {
    warn "would delete: $path\n";
    return;
  }
  return unless -d $path;
  remove_empty_path($path,{
    remove_contents => 1,
    exclude => [ $ticket->ticket_type_name ]
  });
}

sub do_delete {
  my ($ticket) = @_;

  my $dt = $ticket->created_at;
  my $at = $dt->ymd.' '.$dt->hms;
  warn "deleting ".($ticket->ticket_name)." ($at)\n";
  my %path;
  my $job_iter = job_iterator($ticket);
  while(my $job = $job_iter->next) {
    my @path = split('/',$job->job_dir);
    pop @path;
    $path{join('/',@path)} = 1;
  }
  foreach my $path (keys %path) {
    eval { delete_path($ticket,$path); };
    if($@) {
      warn "Error deleting '$path': $@\n";
      return;
    }
  }
  $ticket->mark_deleted unless $dry or $ticket->status eq 'Deleted';
}

sub find_old {
  my ($dir,$num,$end) = @_;

  return [] if time > $end;
  my @out;
  opendir(DIR,$dir) || return;
  my @subdirs;
  foreach my $f (readdir(DIR)) {
    next if $f =~ /^\./;
    push @subdirs,"$dir/$f" if -d "$dir/$f";
    next unless $f =~ /^info\./;
    next unless (time - (stat("$dir/$f"))[9]) > $validity;
    push @out,"$dir/$f";
  }
  closedir DIR;
  @subdirs = shuffle(@subdirs);
  while(@out < $num and @subdirs) {
    my $subdir = pop @subdirs;
    push @out,@{find_old($subdir,$num,$end)};
  }
  return \@out;
}

# Super mode
if($super) {
  # ... build list of old tickets
  my $dir = "$SD->{'ENSEMBL_TMP_DIR_TOOLS'}/temporary/tools";
  my $valid_days = $validity/24/60/60;
  my %old_tickets;
  my $cmd = "script -q -c 'find $dir -name info\\* -mtime +$valid_days' /dev/null";
  my @list = @{find_old($dir,100,time+30)};
  my $count = 0;
  foreach (@list) {
    if(open(INFO,'<',$_)) {
      while(<INFO>) {
        next unless /^Ticket: (.*)/;
        $old_tickets{$1}=1;
      }
      close INFO;
    }
    $count++;
    last if $limit != -1 and $count > $limit;
  }
  if(scalar(keys %old_tickets)) {
    warn "found ".scalar(keys %old_tickets)." old tickets to check\n";
    my $iter =
      ORM::EnsEMBL::DB::Tools::Manager::Ticket->get_objects_iterator(
        'query' => [ 'owner_type' => { 'ne' => 'user' },
                     't1.status' => { 'eq' => 'Deleted'},
         't1.ticket_name' => [keys %old_tickets] ],
        'multi_many_ok' => 1,
        'limit' => $limit,
      );
    if ($iter->error) {
      warn "ERROR: ".($iter->error)."\n";
      exit 1;
    }
    while (my $ticket = $iter->next) {
      warn "already deleted from db: ".($ticket->ticket_name)."\n";
      if (!$ticket->calculate_life_left($validity)) {
        if(we_can_delete($ticket)) {
          do_delete($ticket);
          delete $old_tickets{$ticket->ticket_name};
        }
      }
    }
    warn "cannot delete old tickets ".join(', ',keys %old_tickets)."\n" if keys %old_tickets;
  }
}

# Main loop
my $iter = 0;
my $each_time = 1000;
while($limit>0 or $limit==-1) {
  $iter++;
  my $this_time = $each_time;
  $this_time = $limit if $limit != -1 and $limit < $this_time;
  $limit -= $this_time if $limit > -1;
  warn "Iteration $iter, retrieving $this_time tickets\n";
  my $tickets_iterator =
    ORM::EnsEMBL::DB::Tools::Manager::Ticket->get_objects_iterator(
      'query'         => [ 'owner_type' => {'ne' => 'user'},
         'status' => {'ne' => 'Deleted'} ],
      'sort_by'       => 'created_at ASC',
      'multi_many_ok' => 1,
      'limit'         => $this_time, # don't fill memory
      #'debug'         => 1,
    );
  if ($tickets_iterator->error) {
    warn "ERROR: ".($tickets_iterator->error)."\n";
    exit 1;
  }
  my $successes = 0;
  while (my $ticket = $tickets_iterator->next) {
    if (!$ticket->calculate_life_left($validity)) {
      if(we_can_delete($ticket)) {
        do_delete($ticket);
        $successes++;
      } else {
        warn "cannot delete ".($ticket->ticket_name)."\n";
      }
    }
  }
  if(!$successes) {
    warn "no successes, exiting\n";
    last;
  }
}

exit 0;

