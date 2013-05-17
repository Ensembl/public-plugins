#!/usr/local/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Date::Parse; 
use DBI;
use Getopt::Long qw(GetOptions);


# Help
sub usage {
  print("This script copies the data from old user db schema to the newer schema to make it compatible with this plugin.\n");
  print("\t-host=<database host>    \tServer address where database is hosted.\n");
  print("\t-dbname=<database name>  \tName of the existing user database\n");
  print("\t-user=<User name>        \tUser name for connecting to the db\n");
  print("\t-pass=<password>         \tPassword (default to null)\n");
  print("\t-port=<port>             \tDatbaase port (defaults to 3306)\n");
  print("\t--help                   \tDisplays this info and exits (optional)\n" );
  exit;
}

our @random_chars = ('a'..'z','A'..'Z','0'..'9','_');
sub random_string {
  my $len = shift || 8;
  return join '', map { $random_chars[ rand @random_chars ] } (1..$len);
}

sub hash_to_string {
  my $hash  = shift;
  my $str   = Data::Dumper->new([ $hash ]);
  $str->Sortkeys(1);
  $str->Useqq(1);
  $str = $str->Dump;
  $str = join '', map {$_ =~ s/^\s*//; $_} split "\n", $str;
  $str =~ s/^[^\=]+\=\s*|\;$//g;
  return $str;
}

sub sort_records {
  my $rtype = $a->{'record_type'};
  return $a->{"${rtype}_record_id"} <=> $b->{"${rtype}_record_id"} if $rtype eq $b->{'record_type'};
  
  my $x = str2time($a->{'created_at'});
  my $y = str2time($b->{'created_at'});
  return -1 unless $x;
  return 1 unless $y;
  return $x <=> $y;
}


# Get arguments
my ($host, $dbname, $username, $pass);
my $port = 3306;
GetOptions(
  'host=s'    => \$host,
  'dbname=s'  => \$dbname,
  'user=s'    => \$username,
  'pass=s'    => \$pass,
  'port=i'    => \$port,
  'help'      => \&usage
);


# Validate arguments
print "Argument(s) missing.\n" and usage if (!$host || !$dbname || !$username);


# Other variables
my $backup_table_prefix = 'old_schema_';
my ($dbh, $sth, $counter, $counter_1);


# Connect to db
$dbh = DBI->connect(sprintf('DBI:mysql:database=%s;host=%s;port=%s', $dbname, $host, $port), $username, $pass || '')
  or die('Could not connect to the database');


$sth = $dbh->prepare('SHOW TABLES');
$sth->execute;
my %existing_tables = map {$_->[0] => 1} @{$sth->fetchall_arrayref};
my @retired_tables  = qw(group_member group_record user_record user webgroup);
my @new_tables      = qw(group_member record user login webgroup);


# Any table missing?
exists $existing_tables{$_} or exists $existing_tables{$backup_table_prefix.$_} or die("Error: Table $_ is missing.\n") for @retired_tables;


# Create the backups of existing dbs
for (@retired_tables) {
  my $backup_table = $backup_table_prefix.$_;
  if (exists $existing_tables{$backup_table}) {
    print "Table `$backup_table` already exists, skipping backing up table `$_`\n";
  } else {
    print "Renaming table `$_` to `$backup_table`";
    $dbh->prepare("RENAME TABLE `$_` TO `$backup_table`")->execute;
    print "... DONE\n";
  }
}


# Remove the new tables created from an earlier attempt to run this script (in case it failed in-between)
for (@new_tables) {
  if (exists $existing_tables{$_}) {
    print "Removing table `$_`";
    $dbh->prepare("DROP TABLE IF EXISTS `$_`")->execute;
    print "... DONE\n";
  }
}


# Create new tables
my @new_tables_sql = (
  "CREATE TABLE `group_member` (
    `group_member_id` int(11) NOT NULL AUTO_INCREMENT,
    `webgroup_id` int(11) NOT NULL DEFAULT '0',
    `user_id` int(11) NOT NULL DEFAULT '0',
    `level` enum('member','administrator') NOT NULL DEFAULT 'member',
    `status` enum('active','inactive','pending','barred') NOT NULL DEFAULT 'active',
    `member_status` enum('active','inactive','pending','barred') NOT NULL DEFAULT 'inactive',
    `data` text,
    `created_by` int(11) DEFAULT NULL,
    `created_at` datetime DEFAULT NULL,
    `modified_by` int(11) DEFAULT NULL,
    `modified_at` datetime DEFAULT NULL,
    PRIMARY KEY (`group_member_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;",
  
  "CREATE TABLE `record` (
    `record_id` int(11) NOT NULL AUTO_INCREMENT,
    `record_type` enum('user','group') NOT NULL DEFAULT 'user',
    `record_type_id` int(11) DEFAULT NULL,
    `type` varchar(255) DEFAULT NULL,
    `data` text,
    `created_by` int(11) DEFAULT NULL,
    `created_at` datetime DEFAULT NULL,
    `modified_by` int(11) DEFAULT NULL,
    `modified_at` datetime DEFAULT NULL,
    PRIMARY KEY (`record_id`),
    KEY `record_type_idx` (`record_type_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;",
  
  "CREATE TABLE `user` (
    `user_id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) DEFAULT NULL,
    `email` varchar(255) DEFAULT NULL,
    `data` text,
    `organisation` varchar(255) DEFAULT NULL,
    `country` varchar(2) DEFAULT NULL,
    `status` enum('active','suspended') NOT NULL DEFAULT 'active',
    `salt` varchar(8) DEFAULT NULL,
    `created_by` int(11) DEFAULT NULL,
    `created_at` datetime DEFAULT NULL,
    `modified_by` int(11) DEFAULT NULL,
    `modified_at` datetime DEFAULT NULL,
    PRIMARY KEY (`user_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;",
  
  "CREATE TABLE `login` (
    `login_id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` int(11) DEFAULT NULL,
    `identity` varchar(255) DEFAULT NULL,
    `type` enum('local','openid','ldap') NOT NULL DEFAULT 'local',
    `data` text,
    `status` enum('active','pending') NOT NULL DEFAULT 'pending',
    `salt` varchar(8) DEFAULT NULL,
    `created_by` int(11) DEFAULT NULL,
    `created_at` datetime DEFAULT NULL,
    `modified_by` int(11) DEFAULT NULL,
    `modified_at` datetime DEFAULT NULL,
    PRIMARY KEY (`login_id`),
    KEY `identityx` (`identity`),
    KEY `user_idx` (`user_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;",
  
  "CREATE TABLE `webgroup` (
    `webgroup_id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) DEFAULT NULL,
    `blurb` text,
    `data` text,
    `type` enum('open','restricted','private') DEFAULT 'restricted',
    `status` enum('active','inactive') DEFAULT 'active',
    `created_by` int(11) DEFAULT NULL,
    `created_at` datetime DEFAULT NULL,
    `modified_by` int(11) DEFAULT NULL,
    `modified_at` datetime DEFAULT NULL,
    PRIMARY KEY (`webgroup_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
);

for (@new_tables_sql) {
  $_ =~ /^CREATE\sTABLE\s\`([a-z_]+)\`/;
  print "Creating table `$1`";
  $dbh->prepare($_)->execute;
  print "... DONE\n";
}


# Populate data from old tables to new ones
print "\nExporting data from `${backup_table_prefix}user` table to `login` and `user` tables.\n";
$sth = $dbh->prepare("SELECT * FROM `${backup_table_prefix}user`");
$sth->execute;
my $user_rows = $sth->fetchall_hashref('user_id');
my $user_rows_with_email = {};

for (sort keys %$user_rows) {
  my $email = lc $user_rows->{$_}->{'email'};
  if ($email !~ /\@/) { # if invalid email
    print "\tTable `user`: Ignoring row with primary key $_ (invalid email address '$email')\n";
    next;
  }
  if (exists $user_rows_with_email->{$email}) { # if duplicate email
    
    my $message   = "\tTable `user`: Ignoring row with primary key %d (duplicate email '$email')\n";
    my $current   = $user_rows->{$_};
    my $existing  = $user_rows_with_email->{$email};

    if ($current->{'status'} eq 'suspended') { # current row is suspended, overwrite existing one
      print sprintf $message, $existing->{'user_id'};
    } elsif ($current->{'status'} eq 'active') { # current row is active, overwrite existing one unless existing one is 'suspended' 
      if ($existing->{'status'} eq 'suspended') {
        print sprintf $message, $current->{'user_id'};
        next;
      } else {
        print sprintf $message, $existing->{'user_id'};
      }
    } else { # current row is pending, ignore it
      print sprintf $message, $current->{'user_id'};
      next;
    }
  }
  $user_rows_with_email->{$email} = delete $user_rows->{$_};
}

$user_rows = {};

# insert rows to user and login tables
$counter = 0;
for (sort {$a->{'user_id'} <=> $b->{'user_id'}} values %$user_rows_with_email) {

  my $email = lc $_->{'email'};

  $sth = $dbh->prepare("INSERT INTO `user` (
              `user_id`,
              `name`,
              `email`,
              `data`,
              `organisation`,
              `country`,
              `status`,
              `salt`,
              `created_by`,
              `created_at`,
              `modified_by`,
              `modified_at`
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
  );

  $sth->execute(
              $_->{'user_id'},
              $_->{'name'},
              $email,
              '{}',
              $_->{'organisation'},
              undef,
              $_->{'status'} eq 'suspended' ? 'suspended' : 'active',
              $_->{'status'} eq 'pending' ? 'ensembl' : random_string(8),
              $_->{'created_by'}  || undef,
              $_->{'created_at'}  || undef,
              $_->{'modified_by'} || undef,
              $_->{'modified_at'} || undef
  );

  $sth = $dbh->prepare("INSERT INTO `login` (
              `login_id`,
              `user_id`,
              `identity`,
              `type`,
              `data`,
              `status`,
              `salt`,
              `created_by`,
              `created_at`,
              `modified_by`,
              `modified_at`
            ) VALUES (NULL, ?, ?, 'local', ?, ?, ?, ?, ?, ?, ?);"
  );

  my $data = {
    'country'       => '',
    'email'         => $email,
    'name'          => $_->{'name'} || '',
    'organisation'  => $_->{'organisation'} || '',
    'password'      => $_->{'password'}     || ''
  };

  $sth->execute(
              $_->{'user_id'},
              $email,
              hash_to_string($data),
              $_->{'status'} eq 'pending' ? 'pending' : 'active',
              random_string(8),
              $_->{'created_by'}  || undef,
              $_->{'created_at'}  || undef,
              $_->{'modified_by'} || undef,
              $_->{'modified_at'} || undef
  );
  
  $counter++;
  $user_rows->{$_->{'user_id'}} = 1;
}

$user_rows_with_email = undef;

print "\nDONE: $counter rows added to `login` and `user` table.\n";

print "\nExporting data from `${backup_table_prefix}webgroup` table to `webgroup` table and from `${backup_table_prefix}group_member` table to `group_member`.\n";

$sth = $dbh->prepare("SELECT * FROM `${backup_table_prefix}webgroup`");
$sth->execute;
my $webgroup_rows = $sth->fetchall_hashref('webgroup_id');

$sth = $dbh->prepare("SELECT * FROM `${backup_table_prefix}group_member`");
$sth->execute;
my $membership_rows = $sth->fetchall_hashref('group_member_id');

for (sort keys %$membership_rows) {
  my $group_id  = $membership_rows->{$_}{'webgroup_id'};
  my $user_id   = $membership_rows->{$_}{'user_id'};

  unless (exists $webgroup_rows->{$group_id}) { # ignore if related group is missing
    print "\tTable `group_member`: Ignoring row with primary key $_ (Related group with id $group_id does not exist in the `webgroup` table)\n";
    next;
  }
  
  unless (exists $user_rows->{$user_id}) { # ignore if related user is missing
    print "\tTable `group_member`: Ignoring row with primary key $_ (Related user with id $user_id does not exist in the `user` table)\n";
    next;
  }

  push @{$webgroup_rows->{$group_id}->{'memberships'} ||= []}, $membership_rows->{$_};
}

$membership_rows = undef;
my $group_rows = {};

# insert rows in webgroup and group_member tables
$counter = 0;
$counter_1 = 0;
for (sort keys %$webgroup_rows) {
  my $row = $webgroup_rows->{$_};
  unless (exists $row->{'memberships'}) { # ignore if the group doesn't have any members
    print "\tTable `webgroup` : Ignoring row with primary key $_ (This group doesn't have any member)\n";
    next;
  }
  
  unless ($row->{'name'}) {
    print "\tTable `webgroup` : Ignoring row with primary key $_ (Group name missing)\n";
    print "\tTable `group_member`: Ignoring row with primary key $_->{'group_member_id'} (Related group with id $_->{'webgroup_id'} does not exist in the `webgroup` table)\n" for @{$row->{'memberships'}};
    next;
  }

  $sth = $dbh->prepare("INSERT INTO `webgroup` (
            `webgroup_id`,
            `name`,
            `blurb`,
            `data`,
            `type`,
            `status`,
            `created_by`,
            `created_at`,
            `modified_by`,
            `modified_at`
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
  );

  $sth->execute(
            $row->{'webgroup_id'},
            $row->{'name'},
            $row->{'blurb'},
            $row->{'data'} || '{}',
            $row->{'type'},
            $row->{'status'},
            $row->{'created_by'}  || undef,
            $row->{'created_at'}  || undef,
            $row->{'modified_by'} || undef,
            $row->{'modified_at'} || undef
  );
    
  for (sort {$a->{'group_member_id'} <=> $b->{'group_member_id'}} @{$row->{'memberships'}}) { # insert all membership info in the group_member table
  
    $sth = $dbh->prepare("INSERT INTO `group_member` (
              `group_member_id`,
              `webgroup_id`,
              `user_id`,
              `level`,
              `status`,
              `member_status`,
              `data`,
              `created_by`,
              `created_at`,
              `modified_by`,
              `modified_at`
            ) VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
    );
  
    $sth->execute(
              $row->{'webgroup_id'},
              $_->{'user_id'},
              $_->{'level'} eq 'superuser' ? 'administrator' : $_->{'level'},
              $_->{'status'},
              $_->{'member_status'},
              '{}',
              $_->{'created_by'}  || undef,
              $_->{'created_at'}  || undef,
              $_->{'modified_by'} || undef,
              $_->{'modified_at'} || undef
    );
    
    $counter_1++;
  }

  $counter++;
  
  $group_rows->{$row->{'webgroup_id'}} = 1;
  
  delete $row->{'memberships'};
}
$webgroup_rows = undef;

print "\nDONE: $counter rows added to `webgroup` table and $counter_1 to `group_member` table.\n";

print "\nExporting data from `${backup_table_prefix}group_record` and `${backup_table_prefix}user_record` table to `record` table.\n";

my $ignore_record_types = "'".join("', '", qw(configuration current_config currentconfig drawer info infobox invite mixer opentab sortable))."'";

print "\n\tTable `user_record` and `group_record`: Ignoring records of type: $ignore_record_types\n";

$sth = $dbh->prepare("SELECT * FROM `${backup_table_prefix}user_record` where `type` not in ($ignore_record_types)");
$sth->execute;
my $user_record_rows = $sth->fetchall_hashref('user_record_id');
my $record_rows = {};

for (keys %$user_record_rows) {
  my $user_id = $user_record_rows->{$_}{'user_id'};
  unless (exists $user_rows->{$user_id}) { # ignore if related user doesn't exist
    print "\tTable `user_record`: Ignoring row with primary key $_ (Related user with id $user_id does not exist in the `user` table)\n";
    next;
  }
  $record_rows->{$_} = delete $user_record_rows->{$_};
  $record_rows->{$_}->{'record_type'} = 'user';
}

$sth = $dbh->prepare("SELECT * FROM `${backup_table_prefix}group_record` where `type` not in ($ignore_record_types)");
$sth->execute;
my $group_record_rows = $sth->fetchall_hashref('group_record_id');

for (keys %$group_record_rows) {
  my $group_id = $group_record_rows->{$_}{'webgroup_id'};
  unless (exists $group_rows->{$group_id}) { # ignore if related group doesn't exist
    print "\tTable `group_record`: Ignoring row with primary key $_ (Related group with id $group_id does not exist in the `webgroup` table)\n";
    next;
  }
  $record_rows->{$_} = delete $group_record_rows->{$_};
  $record_rows->{$_}->{'record_type'} = 'group';
}

# insert all record rows into the record table
$counter = 0;
for (sort sort_records values %$record_rows) {

  $sth = $dbh->prepare("INSERT INTO `record` (
            `record_id`,
            `record_type`,
            `record_type_id`,
            `type`,
            `data`,
            `created_by`,
            `created_at`,
            `modified_by`,
            `modified_at`
          ) VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?);"
  );

  my $data = eval($_->{'data'});
  delete $data->{'cloned_from'};
  if ($_->{'type'} eq 'favourite_tracks') {
    for (keys %$data) {
      $data->{$_} = defined $data->{$_} ? eval($data->{$_}) : undef;
    }
  } elsif ($_->{'type'} eq 'bookmark') {
    if ($data->{'shortname'}) {
      $data->{'description'} ||= $data->{'name'};
      $data->{'name'} = delete $data->{'shortname'};
    }
    if (!$data->{'name'}) { 
      print "\tTable `".$_->{'record_type'}."_record`: Ignoring row with primary key ".$_->{$_->{'record_type'}."_record_id"}." (Missing bookmark name)\n";
      next;
    }
  }

  $sth->execute(
            $_->{'record_type'},
            $_->{'webgroup_id'} || $_->{'user_id'},
            $_->{'type'},
            hash_to_string($data),
            $_->{'created_by'}  || undef,
            $_->{'created_at'}  || undef,
            $_->{'modified_by'} || undef,
            $_->{'modified_at'} || undef
  );
  
  $counter++;
}

$user_record_rows = undef;
$group_record_rows = undef;
$record_rows = undef;

print "\nDONE: $counter rows added to `record` table.\n";

$dbh->disconnect;

print "\nDONE\n";

exit;