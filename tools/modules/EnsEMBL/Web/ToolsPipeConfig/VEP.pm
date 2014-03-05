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

  my $species_defs    = $conf->species_defs;
  my $script_options  = $species_defs->ENSEMBL_VEP_SCRIPT_DEFAULT_OPTIONS;
  my $perl_bin        = join ' ', $species_defs->ENSEMBL_TOOLS_PERL_BIN, '-I', $species_defs->ENSEMBL_TOOLS_BIOPERL_DIR, map(sprintf('-I %s/%s', $species_defs->ENSEMBL_LSF_CODE_LOCATION, $_), @{$species_defs->ENSEMBL_TOOLS_LIB_DIRS});

  return [{
    '-logic_name'     => 'VEP',
    '-module'         => 'EnsEMBL::Web::RunnableDB::VEP::Submit',
    '-parameters'     => {
      'ticket_db'       => $conf->o('ticket_db'),
      'script'          => $conf->o('ensembl_codebase').'/'.$species_defs->ENSEMBL_VEP_SCRIPT,
      'script_options'  => { map { defined $script_options->{$_} ? ( $_ => $script_options->{$_} ) : () } keys %$script_options }, # filter out the undef values
      'perl_bin'        => $perl_bin
    },
    '-analysis_capacity'  => 12,
    '-meadow_type'    => 'LSF',
    '-rc_name'        => $conf->species_defs->ENSEMBL_VEP_LSF_QUEUE
  }];
}

sub pipeline_validate {
  my ($class, $conf) = @_;

  my $species_defs = $conf->species_defs;
  my @errors;

  # TODO

  return @errors;
}

1;
