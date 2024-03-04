#!/usr/bin/env perl

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

### BLAT gfClient's 'blast8' type output (that we save in the tools database results table) does not contain alignments.
### So in order to get BTOP like alignments (as provided by BLAST), this script reads the 'blast' type output provided
### by BLAT gfClient, parses the alignment strings, converts them to BLAST's BTOP and adds them as a new column to the
### 'blast8' type output file (tab separated file)

### Arguments
###  --in   'blast' type output file that contains alignment strings
###  --out  'blast8' type tab seperated file to which the BTOP strings get appended as an extra column

use strict;
use warnings;
no warnings 'substr';

use FileHandle;

my $params = { @ARGV };

die('Invalid arguments')          unless exists $params->{'--in'} && exists $params->{'--out'};
die('Input file does not exist')  unless -e $params->{'--in'} && -r $params->{'--in'};
die('Output dir does not exist')  unless -e $params->{'--out'} && -w $params->{'--out'};

my @alignments;

# Read file and create btop strings
{
  my $fh    = FileHandle->new("< $params->{'--in'}");
  my $text  = join '', $fh->getlines;
  $fh->close;

  @alignments = split m/(?= Score \= )/, $text;

  shift @alignments; # throw away the headers

  @alignments = map {

    my ($flag, $gutter, @q, @g);

    my @lines = map {
      $gutter = length $1 if $_ =~ /(^Query\:[\s0-9]+)/;
      $_ = substr($_, $gutter, 60) || '';
      uc($_ =~ /^\|/ && $_ || [ split(' ', $_) ]->[0] || '');
    } grep {
      $flag = 1 if $_ && $_ =~ /^Query/;
      $flag && $_ && !m/Database/;
    } split "\n", $_;

    while (my ($l1, undef, $l3) = splice @lines, 0, 3) {
      push @q, $l1;
      push @g, $l3;
    }

    @q = split '', join '', @q;
    @g = split '', join '', @g;

    my $counter = 0;
    my $btop    = '';

    for (0..$#q) {
      $counter++, next if $q[$_] eq $g[$_];
      $btop    .= ($counter || '') . $q[$_] . $g[$_];
      $counter  = 0;
    }

    $btop .= $counter || '';

    $btop;

  } @alignments;
}

# Write btop string to the tab file
{

  my $fh    = FileHandle->new("< $params->{'--out'}");
  my @lines = $fh->getlines;
  $fh->close;

  # if lines not same as alignments
  die('Number of alignments not same as number of results') if @lines != @alignments;

  for (0..$#lines) {
    chomp $lines[$_];
    $lines[$_] .= "\t$alignments[$_]\n";
  }

  my $fh_w  = FileHandle->new("> $params->{'--out'}");
  $fh_w->print(@lines);
  $fh_w->close;
}
