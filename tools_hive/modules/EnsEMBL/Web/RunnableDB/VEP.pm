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

package EnsEMBL::Web::RunnableDB::VEP;

### Hive Process RunnableDB for VEP

use strict;
use warnings;

use parent qw(EnsEMBL::Web::RunnableDB);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Tools::FileHandler qw(file_get_contents);

sub run {
  my $self = shift;

  my $perl_bin        = $self->param('perl_bin');
  my $script          = $self->param('script');
  my $work_dir        = $self->param('work_dir');
  my $config          = $self->param('config');
  my $options         = $self->param('script_options') || {};
  my $log_file        = "$work_dir/lsf_log.txt";

  $options->{"--$_"}  = '' for qw(force quiet vcf tabix stats_text cache); # we need these options set on always!
  $options->{"--$_"}  = sprintf '"%s/%s"', $work_dir, delete $config->{$_} for qw(input_file output_file stats_file);
  $options->{"--$_"}  = $config->{$_} eq 'yes' ? '' : $config->{$_} for grep { defined $config->{$_} && $config->{$_} ne 'no' } keys %$config;

  my $command         = EnsEMBL::Web::SystemCommand->new($self, "$perl_bin $script", $options)->execute({'log_file' => $log_file});

  return unless $command->error_code;

  throw exception('HiveException', join('', file_get_contents($log_file)));
}

1;
