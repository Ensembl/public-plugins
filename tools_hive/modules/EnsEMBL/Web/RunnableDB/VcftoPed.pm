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

package EnsEMBL::Web::RunnableDB::VcftoPed;

### Hive Process RunnableDB for Allele frequency tool

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

  my $work_dir     = $self->param_required('work_dir');
  my $tools_dir    = $self->param_required('tools_dir');
  my $bgzip        = $self->param_required('bgzip');
  my $input_file   = $self->param_required('input_file');
  my $sample_panel = $self->param_required('sample_panel');
  my $population   = $self->param_required('population');
  my $region       = $self->param_required('region');
  my $ouput_ped    = $self->param_required('output_ped');
  my $ouput_info   = $self->param_required('output_info');
  my $base         = $self->param_required('base');
  my $biallelic    = $self->param_required('biallelic');
  my $code_root    = $self->param_required('code_root');
  
  #set the population parameter for multiple population (-population GBR -population FIN)
  $population =~ s/,/ -population /gi;

  $self->param('__input_file', $input_file);
  $self->param('__region', $region);
  $self->param('__base', $base);
  $self->param('__biallelic', $biallelic);
  $self->param('__output_ped', $ouput_ped);
  $self->param('__output_info', $ouput_info);
  $self->param('__work_dir', $work_dir);
  $self->param('__population', $population);
  $self->param('__tools_dir', $tools_dir);
  $self->param('__bgzip', $bgzip);  
  $self->param('__sample_panel', $sample_panel);
  $self->param('__log_file', sprintf('%s/vcftoped.log', $work_dir ));  
}

sub run {
  my $self      = shift;
  my $log_file  = $self->param('__log_file');
  my $work_dir  = $self->param('__work_dir');
  my $tools_dir = $self->param('__tools_dir');
  my $bgzip     = $self->param('__bgzip');  

  my $command = EnsEMBL::Web::SystemCommand->new($self, sprintf('cd %s;perl %s ', $work_dir, $self->param('VP_bin_path')), {
    '-vcf'            => $self->param('__input_file'),
    '-sample_panel'   => $self->param('__sample_panel'),
    '-region'         => $self->param('__region'),
    '-base'           => $self->param('__base'),
    '-biallelic_only' => $self->param('__biallelic'),
    '-population'     => $self->param('__population'),
    '-tools_dir'      => $self->param('__tools_dir'),
    '-output_dir'     => $self->param('__work_dir'),
    '-output_ped'     => $self->param('__output_ped'),
    '-output_info'    => $self->param('__output_info'),
  })->execute({
    'log_file'    => $log_file,
  });
  
  #cleanup process (removing .tbi file, not needed)
  my $index_file = glob("$work_dir/*.tbi");
  if($index_file && -s $index_file) {
    my $rm_cmd = EnsEMBL::Web::SystemCommand->new($self, "rm ".$self->param('__work_dir')."/*.tbi")->execute();
    if($rm_cmd && $rm_cmd->error_code) {
      throw exception('HiveException', "Error in deleting index file: ".$rm_cmd->error_code);
    } 
  }
  
  #Compressing output PED file
  my $ped_file = join('/', $work_dir, $self->param('__output_ped'));
  if($ped_file && -s $ped_file) {
    my $bg_cmd = EnsEMBL::Web::SystemCommand->new($self, "$bgzip -c $ped_file > $ped_file.gz; rm $ped_file")->execute();
    if($bg_cmd && $bg_cmd->error_code) {
      throw exception('HiveException', "Error in compressing output file: ".$bg_cmd->error_code);
    }   
  }
  
  # throw exception if process failed
  if (my $error_code = $command->error_code) {
    my $error_details = join('', grep(/MSG/, file_get_contents($log_file)));
    ($error_details) = file_get_contents($log_file) if(!$error_details);
    throw exception('HiveException', "\n".$error_details);
  }

  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $work_dir    = $self->param('work_dir');
  my $output_file = $self->param('__output_info');

  #if there is some results in the output file then 
  if(-s "$work_dir/$output_file") {
    $self->save_results($job_id, {}, [{"dummy" => "VCF to PED results obtained"}]); #for now storing dummy results as the output is stored in an output file
  }

  return 1;
}

1;
