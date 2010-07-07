#!/usr/local/bin/perl

### Sample script for using Rose-derived ORM objects to manipulate database records

use strict;
use warnings;
use Carp;

use FindBin qw($Bin);
use File::Basename qw( dirname );

use Pod::Usage;
use Getopt::Long;

my ( $SERVERROOT, $help, $info, $date);

BEGIN{
  &GetOptions( 
	      'help'      => \$help,
	      'info'      => \$info,
          'date=s'    => \$date,
	     );
  
  pod2usage(-verbose => 2) if $info;
  pod2usage(1) if $help;
  
  $SERVERROOT = dirname( $Bin );
  $SERVERROOT =~ s#public-plugins/orm##;
  unshift @INC, "$SERVERROOT/conf";
  eval{ require SiteDefs };
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;

  ## This script needs to use plugins!
  my ($i, @plugin_dirs);
  for (reverse @{ $SiteDefs::ENSEMBL_PLUGINS || [] }) {
    if (++$i % 2) {
      push @plugin_dirs, "$_/modules" if -e "$_/modules";
    }
  }
  unshift @INC, reverse @plugin_dirs;
}

print "\n\n";

## First, generate the Rose object directly
## More flexible, but you need to know more about the underlying objects 

use EnsEMBL::ORM::Rose::Manager::Changelog;

my $objects = EnsEMBL::ORM::Rose::Manager::Changelog->get_objects('object_class' => 'EnsEMBL::ORM::Rose::Object::Changelog');

my $i = 1;
foreach my $object (@$objects) {
  print "Rose object $i: ".$object->title;
  print "\n";
  print '...........  '.@{$object->species}.' species';
  print "\n\n";
  $i++;
}

=pod
$objects = EnsEMBL::ORM::Rose::Manager::Changelog->get_changelogs(
              query => [changelog_id => 1]
              );
my $object = $objects->[0];

print 'Rose object: '.$object->title;
print "\n";
print '...........  '.@{$object->species}.' species';
print "\n\n";

## Now let's try doing via the Data::Rose wrapper object
## Needs a Hub, but uses simpler methods to retrieve data

use EnsEMBL::ORM::Data::Rose::Changelog;
use EnsEMBL::Web::Hub;

my $hub = new EnsEMBL::Web::Hub;
my $data = EnsEMBL::ORM::Data::Rose::Changelog->new($hub);

$objects = $data->fetch_by_id(1);
$object = $objects->[0];

print 'Data object: '.$object->title;
print "\n";
print '...........  '.@{$object->species}.' species';
print "\n\n";
=cut

print 'Done!';
print "\n\n";
