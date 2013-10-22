package EnsEMBL::Web::ToolsPipeConfig::VEP;

### Provides configs for VEP for tools pipeline

use strict;
use warnings;

sub default_options {
  my ($class, $conf) = @_;
  my $sd = $conf->species_defs;
  return {
    'vep_options' => {
      'cache_dir'   => $sd->ENSEMBL_VEP_CACHE,
      'script'      => $sd->ENSEMBL_VEP_SCRIPT,
      'perl_bin'    => $sd->ENSEMBL_VEP_PERL_BIN || '/usr/bin/env perl'
    }
  };
}

sub resource_classes {
  my ($class, $conf) = @_;
  my $lsf_queue = $conf->species_defs->ENSEMBL_VEP_LSF_QUEUE;
  return {$lsf_queue => { 'LSF' => "-q $lsf_queue" }};
}

sub pipeline_analyses {
  my ($class, $conf) = @_;
  return [{
    '-logic_name'     => 'VEP',
    '-module'         => 'EnsEMBL::Web::RunnableDB::VEP::Submit',
    '-parameters'     => {
      'ticket_db'       => $conf->o('ticket_db'),
      'options'         => $conf->o('vep_options')
    },
    '-hive_capacity'  => 15,
    '-rc_name'        => $conf->species_defs->ENSEMBL_VEP_LSF_QUEUE
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
