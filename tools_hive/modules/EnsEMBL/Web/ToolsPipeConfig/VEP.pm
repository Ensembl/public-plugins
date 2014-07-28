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

package EnsEMBL::Web::ToolsPipeConfig::VEP;

### Provides configs for VEP for tools pipeline

use strict;
use warnings;

sub resource_classes {
  my ($class, $conf) = @_;
  my $sd          = $conf->species_defs;
  my $lsf_queue   = $sd->ENSEMBL_VEP_LSF_QUEUE;
  my $lsf_timeout = $sd->ENSEMBL_VEP_LSF_TIMEOUT;
  return {$lsf_queue => { 'LSF' => $lsf_timeout ? "-q $lsf_queue -W $lsf_timeout" : "-q $lsf_queue" }};
}

sub pipeline_analyses {
  my ($class, $conf) = @_;

  my $sd = $conf->species_defs;

  return [{
    '-logic_name'           => 'VEP',
    '-module'               => 'EnsEMBL::Web::RunnableDB::VEP',
    '-parameters'           => {
      'ticket_db'             => $conf->o('ticket_db'),
      'perl_bin'              => $sd->ENSEMBL_TOOLS_PERL_BIN,
      'bioperl_dir'           => $sd->ENSEMBL_TOOLS_BIOPERL_DIR,
      'script'                => $sd->ENSEMBL_VEP_SCRIPT,
      'vep_to_web_script'     => $sd->ENSEMBL_VEP_TO_WEB_SCRIPT
    },
    '-analysis_capacity'    => $sd->ENSEMBL_VEP_ANALYSIS_CAPACITY || 12,
    '-meadow_type'          => 'LSF',
    '-rc_name'              => $sd->ENSEMBL_VEP_LSF_QUEUE,
    '-max_retry_count'      => 0,
    '-failed_job_tolerance' => 100
  }];
}

1;
