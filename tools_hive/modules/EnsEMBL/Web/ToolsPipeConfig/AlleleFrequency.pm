=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ToolsPipeConfig::AlleleFrequency;

### Provides configs for Allele frequency for tools pipeline

use strict;
use warnings;

sub resource_classes {
  my ($class, $conf) = @_;
  my $sd    = $conf->species_defs;
  my $queue = $sd->ENSEMBL_AF_QUEUE;

  return { $queue => {'LOCAL' => ''} } if $sd->ENSEMBL_AF_RUN_LOCAL;

  my $lsf_timeout = $sd->ENSEMBL_AF_LSF_TIMEOUT;
  return {$queue => { 'LSF' => $lsf_timeout ? "-q $queue -W $lsf_timeout" : "-q $queue" }};
}

sub pipeline_analyses {
  my ($class, $conf) = @_;

  my $sd = $conf->species_defs;

  return [{
    '-logic_name'           => 'AlleleFrequency',
    '-module'               => 'EnsEMBL::Web::RunnableDB::AlleleFrequency',
    '-parameters'           => {
      'ticket_db'             => $conf->o('ticket_db'),
      'AF_bin_path'           => $sd->ALLELE_FREQUENCY_BIN_PATH,
      'data_dir'              => $sd->ENSEMBL_CHAIN_FILE_DIR,
    },
    '-rc_name'              => $sd->ENSEMBL_AF_QUEUE,
    '-analysis_capacity'    => $sd->ENSEMBL_AF_ANALYSIS_CAPACITY || 4,
    '-meadow_type'          => $sd->ENSEMBL_AF_RUN_LOCAL ? 'LOCAL' : 'LSF',
    '-max_retry_count'      => 0,
    '-failed_job_tolerance' => 100
  }];
}

sub pipeline_validate {
  my ($class, $conf) = @_;

  my @errors;

  my $bin_path = $conf->o('AF_bin_path');
  push @errors, "Binary file $bin_path either seems to be missing or not executable." unless -x $bin_path;

  return @errors;
}

1;
