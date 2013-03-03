#!/usr/local/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);
use File::Basename qw( dirname );
use File::Find;

# --- load libraries needed for reading config ---
use vars qw( $SERVERROOT );
BEGIN{
  $SERVERROOT = dirname( $Bin );
  unshift @INC, "$SERVERROOT/conf";
  eval{ require SiteDefs };
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;
}

use EnsEMBL::Web::Hub;
use EnsEMBL::Web::SpeciesDefs;
use EnsEMBL::Web::Object::Tools;
use Bio::EnsEMBL::Utils::IO qw/iterate_file/;
use Storable qw(nfreeze);
use IO::Compress::Gzip qw(gzip $GzipError);


my $SPECIES_DEFS = EnsEMBL::Web::SpeciesDefs->new();
my $HUB          = EnsEMBL::Web::Hub->new();

#---- load plugins ---
# Ensure that plugins are loaded before parsing the BLAST
# This code copied from conf/perl.startup.pl
my ($i, @plugins, @plugin_dirs);
my @lib_dirs = @{$SPECIES_DEFS->ENSEMBL_LIB_DIRS};

for (reverse @{$SPECIES_DEFS->ENSEMBL_PLUGINS||[]}) {
  if (++$i % 2) {
    push @plugin_dirs, "$_/modules" if -e "$_/modules";
  } else {
    unshift @plugins, $_;
  }
}

unshift @INC, reverse @plugin_dirs; # Add plugin directories to INC so that EnsEMBL::PLUGIN modules can be used

find(\&load_plugins, @plugin_dirs);

# Loop through the plugin directories, requiring .pm files
# The effect of this is that any plugin with an EnsEMBL::Web:: namespace is used to extend that module in the core directory
# Functions that exist in both the core and the plugin will be overwritten, functions that exist only in the plugin will be added
sub load_plugins {
  if (/\.pm$/ && !/MetaDataBlast\.pm/) {
    my $dir  = $File::Find::topdir;
    my $file = $File::Find::name;

    (my $relative_file = $file) =~ s/^$dir\///;
    (my $package = $relative_file) =~ s/\//::/g;
    $package =~ s/\.pm$//g;

    # Regex matches all namespaces which are EnsEMBL:: but not EnsEMBL::Web
    # Therefore the if statement is true for EnsEMBL::Web:: and Bio:: packages, which are the ones we need to overload
    if ($package !~ /^EnsEMBL::(?!Web)/) {
      no strict 'refs';

      # Require the base module first, unless it already exists
      if (!exists ${"$package\::"}{'ISA'}) {
        foreach (@lib_dirs) {
          eval "require '$_/$relative_file'";
          warn $@ if $@ && $@ !~ /^Can't locate/;
          last if exists ${"$package\::"}{'ISA'};
        }
      }

      eval "require '$file'"; # Require the plugin module
      warn $@ if $@;
    }
  }
}
#--- finished loading plugins ---


my $ticket_name = shift @ARGV;
my $results_file = shift @ARGV;
my $tools_object = new EnsEMBL::Web::Object::Tools;

my $ticket = $tools_object->fetch_ticket_by_name($ticket_name);
my @results = ();
my $now = $tools_object->get_time_now;

iterate_file($results_file, sub {
  my ($line) = @_;

  my @hit_data = split (/\t/, $line); 
  my $q_ori = $hit_data[1] < $hit_data[2] ? 1 : -1; 
  my $t_ori = $hit_data[4] < $hit_data[5] ? 1 : -1;

  my $tstart = $hit_data[4] < $hit_data[5] ? $hit_data[4] : $hit_data[5];
  my $tend = $hit_data[4] < $hit_data[5] ? $hit_data[5] : $hit_data[4];  

    
  my $hit = {
    qid     => $hit_data[0],
    qstart  => $hit_data[1],
    qend    => $hit_data[2],
    qori    => $q_ori,
    qframe  => $hit_data[11],
    tid     => $hit_data[3],
    tstart  => $tstart,
    tend    => $tend, 
    tori    => $t_ori,
    tframe  => $hit_data[12],
    score   => $hit_data[6],
    evalue  => $hit_data[7],
    pident  => $hit_data[8],
    len     => $hit_data[9],
    aln     => $hit_data[10], 
  };  

  my $ticket_id = $ticket->ticket_id;
  my @file_path_data = split (/\//, $results_file); 
  my $sub_job_file = pop @file_path_data;
  my @name_data = split(/\./, $sub_job_file);
  my $sub_job_id = shift @name_data;  
  $sub_job_id =~s/$ticket_id//; 

  my $hit_mapped_to_genomic = map_to_genome($ticket, $hit, $sub_job_id);
  my $chr_name = $hit_mapped_to_genomic->{'gid'};
  my $chr_start   = $hit_mapped_to_genomic->{'gstart'};
  my $chr_end   = $hit_mapped_to_genomic->{'gend'};
  my $serialised = nfreeze($hit_mapped_to_genomic);
  my $serialised_gzip;
  gzip \$serialised => \$serialised_gzip, -LEVEL => 9 or die "gzip failed: $GzipError";
  
  push (@results, {ticket_id  => $ticket_id,  
                   sub_job_id => $sub_job_id, 
                   result     => $serialised, 
                   created_at => $now, 
                   chr_name   => $chr_name,  
                   chr_start  => $chr_start,
                   chr_end    => $chr_end      
  })

});

$ticket->result(\@results);
$ticket->save(cascade => 1);


sub map_to_genome {
  my ($ticket, $hit, $sub_job_id) = @_;
  
  # add genomic coordinates to hit
  my $job_division = get_job_division_data($ticket, $sub_job_id);
  my $species = $job_division->{'species'};
  my $database_type = $job_division->{'type'};

  my $genomic_hit = get_genomic_coordinates($hit, $database_type, $species);
  return $genomic_hit;
}

sub get_job_division_data {
  my ($ticket, $sub_job_id) = @_;
  my $analysis_object = $ticket->analysis;  
  my $database = $analysis_object->{'_database'};
  my $sub_job_adaptor = $tools_object->rose_manager('SubJob');  
  my $sub_job = $sub_job_adaptor->fetch_by_id($sub_job_id); 
  my $frozen_division = $sub_job->job_division; 
  my $job_division = $tools_object->deserialise($frozen_division); 
  return $job_division;
}

sub  get_genomic_coordinates {
  my ($hit, $database_type, $species) = @_;
  my ($g_id, $g_start, $g_end, $g_ori, $g_coords, $g_aln);

  if ($database_type =~/LATESTGP/){
    $g_id = $hit->{'tid'};
    $g_start = $hit->{'tstart'};
    $g_end  = $hit->{'tend'};
    $g_ori  = $hit->{'tori'};
    $g_aln  = $hit->{'aln'}
  } else {
    my $feature_type = $database_type =~ /abinitio/i ? 'PredictionTranscript' : 
                       $database_type =~ /cdna/i ? 'Transcript' : 'Translation';
    my $mapper = $database_type =~ /pep/i ? 'pep2genomic' : 'cdna2genomic';

    my $adaptor = $HUB->get_adaptor('get_' . $feature_type .'Adaptor', 'core', $species);
  
    my $object = $adaptor->fetch_by_stable_id($hit->{'tid'}); 
    if ($feature_type eq 'Translation'){ $object = $object->transcript; }
    my @coords = ( sort { $a->start <=> $b->start }
                   grep { ! $_->isa('Bio::EnsEMBL::Mapper::Gap') }
                   $object->$mapper($hit->{'tstart'}, $hit->{'tend'}, $hit->{'tori'})
                 );

    $g_id = $object->seq_region_name;
    $g_start = $coords[0]->start;  
    $g_end = $coords[-1]->end; 
    $g_ori = $object->strand eq $hit->{'tori'} ? $object->strand : 
             $object->strand  eq '1' ? '1' : '-1';

    $g_coords = \@coords;
  }

  $hit->{'gid'} = $g_id;
  $hit->{'gstart'} = $g_start;
  $hit->{'gend'} = $g_end;
  $hit->{'gori'} = $g_ori;
  $hit->{'species'} = $species;
  $hit->{'g_aln'} = $g_aln; 
  $hit->{'db_type'} = $database_type;
  if ($g_coords){ $hit->{'g_coords'} = $g_coords; }  

  return $hit;
}
1;
