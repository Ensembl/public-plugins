=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ToolsPipeConfig;

### Abstract base class for all ToolsPipeConfig

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use EnsEMBL::Web::Attributes;

sub logic_name        :Abstract;
sub runnable          :Abstract;
sub queue_name        :Abstract;
sub is_farm           :Abstract;
sub farm_timeout       :Abstract;
sub memory_usage      :Abstract;
sub analysis_capacity :Abstract;

sub resource_classes {
  my $class = shift;

  return { $class->_resource_class_name, $class->_format_resource_class };
}

sub pipeline_analyses {
  my ($class, $conf) = @_;

  my $sd = $conf->species_defs;

  return [{
    '-logic_name'           => $class->logic_name,
    '-module'               => $class->runnable,
    '-parameters'           => {},
    '-rc_name'              => $class->_resource_class_name,
    '-analysis_capacity'    => $class->analysis_capacity || 500,
    '-meadow_type'          => $class->is_farm ? 'SLURM' : 'LOCAL',
    '-max_retry_count'      => 0,
    '-failed_job_tolerance' => 100
  }];
}

sub _format_resource_class {
  ## @private
  my $class = shift;

  return { 'LOCAL' => '' } unless $class->is_farm;

  my $queue   = $class->queue_name;
  my $timeout = $class->farm_timeout;
  my $memory  = $class->memory_usage;
  
  $timeout = $timeout ? " -W $timeout" : '';
  $memory  = $memory  ? sprintf('%s', $memory * 1024) : '1600';

  return { 'SLURM' => sprintf(" --time=1-00:00:00  --mem=%s%s -n 8 -N 1", $memory, 'm') };
}

sub _resource_class_name {
  ## @private
  my $class   = shift;
  my $rc      = $class->_format_resource_class;
  my $queue   = $class->queue_name || '';
  my $timeout = ($class->farm_timeout || '') =~ s/\:.+$//r;
  my $memory  = $class->memory_usage || '';
  my $str     = sprintf('%s %s%s %s%s ', $queue, $timeout ? 'T' : '', $timeout, $memory ? 'M' : '', $memory) =~ s/\W+/-/gr;

  return sprintf '%s%s', $str, substr(md5_hex(join(' ', %$rc)), 0, 4);
}

1;
