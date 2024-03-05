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

package EnsEMBL::Web::RunnableDB::VariationPattern;

### Hive Process RunnableDB for Variation Pattern finder tool

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);
use EnsEMBL::Web::File::Utils::URL;

use parent qw(EnsEMBL::Web::RunnableDB);

sub fetch_input {
  ## @override
  my $self = shift;

  my $output_file  = $self->param_required('output_file');
  my $work_dir     = $self->param_required('work_dir');
  my $input_file   = $self->param_required('input_file');
  my $sample_panel = $self->param_required('sample_panel');
  my $region       = $self->param_required('region');  
  my $code_root    = $self->param_required('code_root');
  my $tabix        = $self->param_required('tabix');
  my $host         = $self->param_required('host');
  my $port         = $self->param_required('port');
  my $user         = $self->param_required('user');
  
  # set up perl bin with the required library locations
  try {
    my @modules   = map { -d "$code_root/$_/modules" ? "-I $code_root/$_/modules" : () } @{list_dir_contents($code_root)};
    my $perl_bin  = join ' ', @modules;
       $perl_bin .= ' -I '.$self->param('vcftools_perl_lib') if $self->param('vcftools_perl_lib');
    $self->param('perl_bin', $perl_bin);
  } catch {
    throw exception('HiveException', $_->message(1));
  };

  $self->param('__input_file', $input_file);
  $self->param('__region', $region);
  $self->param('__sample_panel', $sample_panel);
  $self->param('__tabix', $tabix);
  $self->param('__host', $host);
  $self->param('__port', $port);
  $self->param('__user', $user);
  $self->param('__output_file', sprintf('%s/%s', $work_dir, $output_file));
  $self->param('__log_file', sprintf('%s/%s.log', $work_dir, $output_file ));  
  $self->param('__work_dir', $work_dir);
}

sub run {
  my $self      = shift;
  my $log_file  = $self->param('__log_file');

  my $command = EnsEMBL::Web::SystemCommand->new($self, sprintf('cd %s;perl %s %s', $self->param('__work_dir'), $self->param('perl_bin'), $self->param('VPF_bin_path')), {
    '-vcf'                => $self->param('__input_file'),
    '-sample_panel_file'  => $self->param('__sample_panel'),
    '-region'             => $self->param('__region'),
    '-output_dir'         => $self->param('__work_dir'),
    '-tabix'              => $self->param('__tabix'),
    '-host'               => $self->param('__host'),
    '-port'               => $self->param('__port'),
    '-user'               => $self->param('__user'),
    '-output_file'        => $self->param('__output_file')
  })->execute({
    'log_file'    => $log_file,
  });

  # throw exception if process failed
  if (my $error_code = $command->error_code) {
    my $error_details = file_get_contents($log_file);
    throw exception('HiveException', "\n".$error_details);
  }

  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $output_file = $self->param('__output_file');

  my $content     = file_get_contents($output_file, sub { s/\R/\r\n/r });  
    
  #if there is some results in the output file (not just the header in the file)
  if(scalar(split('\n',$content)) > 1) {
    $self->save_results($job_id, {}, [{"dummy" => "Variation pattern finder results obtained"}]); #for now storing dummy results as the output is stored in an output file
  }

  return 1;
}

1;
