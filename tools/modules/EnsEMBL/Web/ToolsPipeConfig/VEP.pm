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

sub default_options {
  return {};
}

sub resource_classes {
  my ($class, $conf) = @_;
  my $lsf_queue = $conf->species_defs->ENSEMBL_VEP_LSF_QUEUE;
  return {$lsf_queue => { 'LSF' => "-q $lsf_queue" }};
}

sub pipeline_analyses {
  my ($class, $conf) = @_;
  my $sd = $conf->species_defs;

  return [{
    '-logic_name'     => 'VEP',
    '-module'         => 'EnsEMBL::Web::RunnableDB::VEP::Submit',
    '-parameters'     => {
      'ticket_db'       => $conf->o('ticket_db'),
      'cache_dir'       => $sd->ENSEMBL_VEP_CACHE,
      'script'          => $conf->o('ensembl_codebase').'/'.$sd->ENSEMBL_VEP_SCRIPT,
      'perl_bin'        => $sd->ENSEMBL_TOOLS_PERL_BIN
    },
    '-hive_capacity'  => 15,
    '-meadow_type'      => 'LSF',
    '-rc_name'          => $conf->species_defs->ENSEMBL_VEP_LSF_QUEUE
  }];
}

sub pipeline_validate {
  my ($class, $conf) = @_;

  my $sd = $conf->species_defs;
  my @errors;

  # TODO

  return @errors;
}

1;
