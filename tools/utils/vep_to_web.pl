#!/usr/bin/env perl

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut

=head1 NAME

vep_to_web.pl

by Will McLaren (wm2@ebi.ac.uk)
=cut

use strict;
use Getopt::Long;
use FileHandle;
use Bio::EnsEMBL::Variation::Utils::Constants;
use Bio::EnsEMBL::Variation::Utils::VEP qw(parse_line validate_vf);

my $file = $ARGV[0] if @ARGV;
die("ERROR: No file specified\n") unless $file;
die("ERROR: File $file does not exist\n") unless -e $file;

my $in_fh = new FileHandle;
 
if($file) {
  # check defined input file exists
  die("ERROR: Could not find input file ", $file, "\n") unless -e $file;
  
  if(-B $file){
    $in_fh->open("zcat $file | " ) or die("ERROR: Could not read from input file $\n");
  }
  else {
    $in_fh->open($file) or die("ERROR: Could not read from input file $file\n");
  }
}
else {
  $in_fh = 'STDIN';
}

my %cons = %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;
  
while(<$in_fh>) {
  next if /^\#/;
  
  chomp;
  
  my $line = $_;
  my ($vf) = @{parse_line({format => 'vcf'}, $line)};
  
  $line =~ m/CSQ\=(.+?)(\;|$|\s)/;
  my $con = (
    sort {$cons{$a}->rank <=> $cons{$b}->rank}
    grep {defined($cons{$_})}
    map {split /\|/}
    map {split /\,/} $1
  )[0];
  
  $vf->{chr} =~ s/^chr//i unless $vf->{chr} =~ /chromosome/i || $vf->{chr} =~ /^CHR\_/;
  $vf->{variation_name} ||= $vf->{chr}.'_'.$vf->{start}.'_'.($vf->{allele_string} || $vf->{class_SO_term});  
  
  if(defined($vf->{allele_string}) && length($vf->{allele_string}) > 50) {
    my @new_alleles;
    
    foreach my $allele(split(/\//, $vf->{allele_string})) {
      if(length($allele) > 50) {
        my $new = length($allele).'BP_SEQ';
        push @new_alleles, $new;
        
        $vf->{variation_name} =~ s/$allele/$new/e;
      }
      else {
        push @new_alleles, $allele;
      }
    }
    
    $vf->{allele_string} = join("/", @new_alleles);
  }
  
  printf(
    "%s\t%i\t%i\t%s\t%s\t%s\t%s\n",
    $vf->{chr}, $vf->{start}, $vf->{end},
    $vf->{allele_string} || $vf->{class_SO_term}, 1,
    $vf->{variation_name},
    $con
  );
}
