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

package EnsEMBL::Web::RunnableDB::FileChameleon;

### Hive Process RunnableDB for File chameleon tool

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);

use parent qw(EnsEMBL::Web::RunnableDB);

sub fetch_input {
  ## @override
  my $self = shift;

  my $fc_bin      = $self->param_required('FC_bin_path');
  my $output_file = $self->param_required('output_file');
  my $config      = $self->param_required('config');
  my $work_dir    = $self->param_required('work_dir');
  my $input_file  = $self->param_required('input_file');
  my $format      = $self->param_required('format');
  my $download    = $self->param_required('just_download');
  my $code_root   = $self->param_required('code_root');
  my $tools_dir   = $self->param_required('tools_dir');
  my $script_path = "$tools_dir/FileChameleon/lib/";
  
  throw exception('HiveException', 'file chameleon package file is either missing or is not executable.') unless -x $fc_bin;
  
  # set up perl bin with the required library locations
  try {
    my @modules   = map { -d "$code_root/$_/modules" ? "-I $code_root/$_/modules" : () } @{list_dir_contents($code_root)};
    #HACK to get file chameleon to work with ensembl-io 95 checkout, once we have a proper fix this needs to be removed
    foreach(@modules) { $_ = $_ =~ /ensembl-io/ ? "-I /nfs/public/release/ensweb/latest/live/www/www_95/ensembl-io/modules" : $_ }
    my $perl_bin  = join ' ','-I', $script_path, @modules;    
    $self->param('perl_bin', $perl_bin);
  } catch {
    throw exception('HiveException', $_->message(1));
  };
  
  $self->param('__input_file', $input_file);
  $self->param('__output_file', sprintf('%s/%s', $work_dir, $output_file));
  $self->param('__log_file', sprintf('%s/%s.log', $work_dir, $output_file));
  $self->param('__config_file', "file://".sprintf('%s/%s', $work_dir, $config));
  $self->param('__format', $format);
  $self->param('__download', $download);
}

sub run {
  my $self      = shift;
  my $log_file  = $self->param('__log_file');
  my $download  = $self->param('__download');

  #no need to execute anything if it is just downloading raw file
  if($download) {  
    return 1;
  } else {
    my $command = EnsEMBL::Web::SystemCommand->new($self, sprintf('perl %s %s', $self->param('perl_bin'), $self->param('FC_bin_path')), {
      '-i'      => $self->param('__input_file'),
      '-o'      => $self->param('__output_file'),
      '-c'      => $self->param('__config_file'),
      '-g'      => '',
      '-format' => $self->param('__format')    
    })->execute({
      'log_file'    => $log_file,
      'output_file' => $self->param('__output_file')
    });

    # throw exception if process failed
    if (my $error_code = $command->error_code) {
      my $error_details = join('', grep(/MSG/, file_get_contents($log_file)));
      ($error_details) = file_get_contents($log_file) if(!$error_details);
      throw exception('HiveException', "\n".$error_details);
    }

    return 1;
  }
}


1;
