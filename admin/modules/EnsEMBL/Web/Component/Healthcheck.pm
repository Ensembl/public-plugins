package EnsEMBL::Web::Component::Healthcheck;

use base qw( EnsEMBL::Web::Component);
use strict;
use warnings;
use Time::Local;

sub friendly_date {
  ### Converts a MySQL datetime field into something human-readable
  my ($self, $datetime) = @_;
  my ($date, $time) = split(' ', $datetime);
  my ($year, $mon, $day) = split('-', $date);
  return '-' unless ($year > 0);
  my ($hour, $min, $sec) = split(':', $time);

  my @months = ('', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
                'September', 'October', 'November', 'December');

  $day =~ s/^0//;

  ## Get day of week
  my $timestamp = timelocal($sec, $min, $hour, $day, $mon-1, $year);
  my $wday = (localtime($timestamp))[6];
  my @days = qw(Sun Mon Tues Wed Thu Fri Sat);

  return $days[$wday].' '.$day.' '.$months[$mon].' at '.$hour.':'.$min;

}

1;
