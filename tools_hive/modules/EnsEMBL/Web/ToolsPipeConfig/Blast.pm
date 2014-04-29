=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ToolsPipeConfig::Blast;

### Provides configs for Blast for tools pipeline
### To add another tool, add a similar package with similar methods

use strict;
use warnings;

sub default_options {
  my ($class, $conf) = @_;
  my $sd = $conf->species_defs;
  return {
    'NCBIBLAST_work_dir'          => $sd->ENSEMBL_TMP_DIR_BLAST,
    'NCBIBLAST_bin_dir'           => $sd->ENSEMBL_NCBIBLAST_BIN_PATH,
    'NCBIBLAST_matrix'            => $sd->ENSEMBL_NCBIBLAST_MATRIX,
    'NCBIBLAST_index_files'       => $sd->ENSEMBL_NCBIBLAST_DATA_PATH,
    'NCBIBLAST_dna_index_files'   => $sd->ENSEMBL_NCBIBLAST_DATA_PATH_DNA,
    'NCBIBLAST_repeat_mask_bin'   => $sd->ENSEMBL_REPEATMASK_BIN_PATH,
#     'WUBLAST_work_dir'            => $sd->ENSEMBL_TMP_DIR_BLAST,
#     'WUBLAST_bin_dir'             => $sd->ENSEMBL_WUBLAST_BIN_PATH,
#     'WUBLAST_matrix'              => $sd->ENSEMBL_WUBLAST_MATRIX,
#     'WUBLAST_index_files'         => $sd->ENSEMBL_WUBLAST_DATA_PATH,
#     'WUBLAST_dna_index_files'     => $sd->ENSEMBL_WUBLAST_DATA_PATH_DNA,
#     'WUBLAST_repeat_mask_bin'     => $sd->ENSEMBL_REPEATMASK_BIN_PATH
  };
}

sub resource_classes {
  my ($class, $conf) = @_;
  my $lsf_queue = $conf->species_defs->ENSEMBL_BLAST_LSF_QUEUE;
  return {$lsf_queue => { 'LSF' => "-q $lsf_queue" }};
}

sub pipeline_analyses {
  my ($class, $conf) = @_;

  my %default_options = map { $_ => $conf->o($_) } keys %{$class->default_options($conf)}; # pass all default_options to hive

  return [{
    '-logic_name'       => 'Blast',
    '-module'           => 'EnsEMBL::Web::RunnableDB::Blast::Submit',
    '-parameters'       => {
      'ticket_db'         => $conf->o('ticket_db'),
      %default_options
    },
    '-hive_capacity'    => 15,
    '-max_retry_count'  => 0,
    '-rc_name'          => $conf->species_defs->ENSEMBL_BLAST_LSF_QUEUE
  }];
}

sub pipeline_validate {
  my ($class, $conf) = @_;

  my $sd = $conf->species_defs;
  my @errors;

#   my $blast_options = $conf->o('blast_options');
#   my $bin_dir       = $blast_options->{'bin_dir'};
#   my $work_dir      = $blast_options->{'work_dir'};
#   if (opendir(DIR, $bin_dir)) {
#     while (my $file = readdir(DIR)) {
#       next if $file =~ /^\./;
#       push @errors, "File $bin_dir/$file may be used later by the script, so it needs to be executable." unless -x "$bin_dir/$file";
#     }
#     closedir(DIR);
#   } else {
#     push @errors, "Directory $bin_dir: BLAST program directory is either not existing, or not accessible.";
#   }
#   unless (-d $work_dir && -w $work_dir) {
#     push @errors, "Work directory $work_dir: BLAST work directory is either not existing, or not writable.";
#   }
# 
#   return @errors;
}

1;
