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

package EnsEMBL::Web::ToolsPipeConfig::AssemblyConverter;

### Provides configs for CrossMap for tools pipeline

use strict;
use warnings;

sub resource_classes {
  my ($class, $conf) = @_;
  my $sd = $conf->species_defs;

  return { $sd->ENSEMBL_AC_LOCAL_QUEUE => {'LOCAL' => ''} } if $sd->ENSEMBL_AC_RUN_LOCAL;

  my $lsf_queue   = $sd->ENSEMBL_AC_LSF_QUEUE;
  my $lsf_timeout = $sd->ENSEMBL_AC_LSF_TIMEOUT;
  return {$lsf_queue => { 'LSF' => $lsf_timeout ? "-q $lsf_queue -W $lsf_timeout" : "-q $lsf_queue" }};
}

sub pipeline_analyses {
  my ($class, $conf) = @_;

  my $sd = $conf->species_defs;

  return [{
    '-logic_name'           => 'AssemblyConverter',
    '-module'               => 'EnsEMBL::Web::RunnableDB::AssemblyConverter',
    '-parameters'           => {
      'ticket_db'             => $conf->o('ticket_db'),
      'AC_bin_path'           => $sd->ASSEMBLY_CONVERTER_BIN_PATH,
    },
    '-rc_name'              => $sd->ENSEMBL_AC_RUN_LOCAL ? $sd->ENSEMBL_AC_LOCAL_QUEUE : $sd->ENSEMBL_AC_LSF_QUEUE,
    '-analysis_capacity'    => $sd->ENSEMBL_AC_ANALYSIS_CAPACITY || 4,
    '-max_retry_count'      => 0,
    '-meadow_type'          => $sd->ENSEMBL_AC_RUN_LOCAL ? 'LOCAL' : 'LSF',
    '-failed_job_tolerance' => 100
  }];
}

sub pipeline_validate {
  my ($class, $conf) = @_;

  my @errors;

  my $bin_path = $conf->o('AC_bin_path');
  push @errors, "Binary file $bin_path either seems to be missing or not executable." unless -x $bin_path;

  return @errors;
}

1;
