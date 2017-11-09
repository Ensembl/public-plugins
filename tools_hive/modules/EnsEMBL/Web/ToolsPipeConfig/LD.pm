=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ToolsPipeConfig::LD;

### Provides configs for VEP for tools pipeline

use strict;
use warnings;

sub resource_classes {
  my ($class, $conf) = @_;
  my $sd    = $conf->species_defs;
  my $queue = $sd->ENSEMBL_VEP_QUEUE;

  return { $queue => {'LOCAL' => ''} } if $sd->ENSEMBL_VEP_RUN_LOCAL;

  my $lsf_timeout = $sd->ENSEMBL_VEP_LSF_TIMEOUT;
  return {$queue => { 'LSF' => $lsf_timeout ? "-q $queue -W $lsf_timeout" : "-q $queue" }};
}

sub pipeline_analyses {
  my ($class, $conf) = @_;
  my $sd = $conf->species_defs;
  return [{
    '-logic_name'           => 'LD',
    '-module'               => 'EnsEMBL::Web::RunnableDB::LD',
    '-parameters'           => {
      'ticket_db'             => $conf->o('ticket_db'),
    },
    '-rc_name'              => $sd->ENSEMBL_VEP_QUEUE,
    '-analysis_capacity'    => $sd->ENSEMBL_VEP_ANALYSIS_CAPACITY || 12,
    '-meadow_type'          => $sd->ENSEMBL_VEP_RUN_LOCAL ? 'LOCAL' : 'LSF',
    '-max_retry_count'      => 0,
    '-failed_job_tolerance' => 100
  }];
}

1;
