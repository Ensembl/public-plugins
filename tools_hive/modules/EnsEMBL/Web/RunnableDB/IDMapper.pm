=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::RunnableDB::IDMapper;

### Hive Process RunnableDB for IDMapper

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Parsers::IDMapper;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);

use parent qw(EnsEMBL::Web::RunnableDB);

sub fetch_input {
  my $self = shift;

  my $code_root   = $self->param_required('code_root');
  my $script_path = $self->param_required('script_path');
  my $work_dir    = $self->param_required('work_dir');
  my $input_file  = $self->param_required('input_file');
  my $output_file = $self->param_required('output_file');

  throw exception('HiveException', 'IDMapper script file is either missing or not accessible.') unless -r "$code_root/$script_path";
  throw exception('HiveException', 'Input file for IDMapper could not be located.') unless -r "$work_dir/$input_file";

  # set up perl bin with the required library locations
  try {
    my @modules   = map { -d "$code_root/$_/modules" ? "-I $code_root/$_/modules" : () } @{list_dir_contents($code_root)};
    my $perl_bin  = join ' ','-I', $script_path, @modules;
    $self->param('perl_bin', $perl_bin);
  } catch {
    throw exception('HiveException', $_->message(1));
  };

  $self->param('__input_file', "$work_dir/$input_file");
  $self->param('__output_file', sprintf('%s/%s', $work_dir, $output_file));
  $self->param('__log_file', sprintf('%s/%s.log', $work_dir, $output_file));
  $self->param('__script_path', "$code_root/$script_path");
}

sub run {
  my $self      = shift;
  my $log_file  = $self->param('__log_file');

  my $command = EnsEMBL::Web::SystemCommand->new($self, sprintf('perl %s %s', $self->param('perl_bin'), $self->param('__script_path')), {
    '--file'      => $self->param('__input_file'),
    '--species'   => $self->param_required('species_production_name'),
    $self->param('host') ? ('--host'      => $self->param('host')) : (),
    $self->param('port') ? ('--port'      => $self->param('port')) : (),
    $self->param('user') ? ('--user'      => $self->param('user')) : (),
    $self->param('pass') ? ('--pass'      => $self->param('pass')) : (),
  })->execute({
    'log_file'    => $log_file,
    'output_file' => $self->param('__output_file')
  });

  # throw exception if process failed
  if (my $error_code = $command->error_code) {
    my ($error_details) = file_get_contents($log_file);
    throw exception('HiveException', $error_details);
  }

  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $output_file = $self->param('__output_file');

  $self->save_results($job_id, {}, EnsEMBL::Web::Parsers::IDMapper->new($self)->parse($output_file));

  return 1;
}

1;
