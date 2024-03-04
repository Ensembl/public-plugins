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

package EnsEMBL::Web::RunnableDB::DataSlicer;

### Hive Process RunnableDB for Data slicer tool

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;

use parent qw(EnsEMBL::Web::RunnableDB);

sub fetch_input {
  ## @override
  my $self = shift;
  
  my $work_dir     = $self->param_required('work_dir');
  my $script_dir   = $self->param_required('script_dir');
  my $tabix        = $self->param_required('tabix');
  my $bgzip        = $self->param_required('bgzip');
  my $samtools     = $self->param_required('samtools');
  my $output_file  = $self->param_required('output_file');
  my $input_file   = $self->param_required('input_file');
  my $region       = $self->param_required('region');
  my $file_format  = $self->param_required('file_format');  
  
  $self->param('__input_file', $input_file);
  $self->param('__region', $region);
  $self->param('__script_dir', $script_dir);
  $self->param('__tabix', $tabix);
  $self->param('__bgzip', $bgzip);
  $self->param('__samtools', $samtools);
  $self->param('__file_format', $file_format);  
  $self->param('__output_file', sprintf('%s/%s', $work_dir, $output_file));
  $self->param('__log_file', sprintf('%s/%s.log', $work_dir, $output_file ));  

  # set up perl bin with the required library locations
  my $perl_bin = ' -I '.$self->param('vcftools_perl_lib') if $self->param('vcftools_perl_lib');
  $self->param('perl_bin', $perl_bin);
}

sub run {
  my $self      = shift;
  
  my $log_file    = $self->param('__log_file');
  my $file_format = $self->param('__file_format');  
  my $input_file  = $self->param('__input_file');
  my $output_file = $self->param('__output_file');
  my $region      = $self->param('__region');  
  my $script_dir  = $self->param('__script_dir');
  my $tabix       = $self->param('__tabix');
  my $bgzip       = $self->param('__bgzip');
  my $samtools    = $self->param('__samtools');
  my $perl_bin    = $self->param('perl_bin');
  
  my $work_dir    = $self->param('work_dir');

  if($file_format eq 'bam') {
  
    #generating preview file (used on the web interface to preview data, first 300 lines)
    my $preview_cmd = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir;$samtools view $input_file $region -H -o bam_preview.txt; $samtools view $input_file $region | head -10 >> bam_preview.txt")->execute();
  
    my $command = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir;$samtools view $input_file $region -h -b -o $output_file; rm *.bai")->execute({
      'log_file'    => $log_file,
    });
    
    throw exception('HiveException', "Subsection file could not be created: ".$command->error_code) unless -s $output_file;

    if($self->param('bai_file')) {
      my $bai_cmd = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir;$samtools index -b $output_file")->execute();
      
      throw exception('HiveException', "Index file could not be created: ".$bai_cmd->error_code) unless -s "$output_file.bai";
    }
  }
  
  if($file_format eq 'vcf') {
    if($self->param('population_value') || $self->param('individuals')){
      my $samples = $self->param('population_value') ? $self->param('population_value') : $self->param('individuals');
      my $sam     = ($samples =~ tr/,//);
      my $sp_file = "split_".$self->param('output_file');
      
      #split file based on region first
      my $split_cmd = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir;$tabix $input_file $region -h | sed -r 's/##samples=\([0-9]+\)/##samples=".$sam."/g;' | $bgzip > $sp_file")->execute();
      throw exception('HiveException', "Could not split file based on region: ".$split_cmd->error_code) unless -s "$work_dir/$sp_file";
      
      my $filter_command = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir;perl $perl_bin $script_dir/vcftools/perl/vcf-subset -f -c $samples $work_dir/$sp_file | $bgzip > $output_file")->execute({
        'log_file'    => $log_file,
      }); 
      
      throw exception('HiveException', "Could not create fitered file: ".$filter_command->error_code) unless -s $output_file;
      
    } else {
      my $vcf_command = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir;$tabix $input_file $region -h | $bgzip > $output_file")->execute({
        'log_file'    => $log_file,
      });      
      throw exception('HiveException', "Subsection VCF file could not be created: ".$vcf_command->error_code) unless -s $output_file;
    }
    #generating preview file (used on the web interface to preview data - only first 5 lines after header)
    my $prev_cmd = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir; $tabix -f -p vcf  $output_file; $tabix -h $output_file NonExistant> preview.vcf; $tabix $output_file $region | head -5 >> preview.vcf ")->execute();    
    
    #deleting unused files
    my $del_cmd = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir;rm *.tbi; rm split_*;")->execute();    
  } 

  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $output_file = $self->param('__output_file');

  $self->save_results($job_id, {}, [{"dummy" => "Data Slicer results obtained"}]) if(-s $output_file); #for now storing dummy results as the output is stored in an output file

  return 1;
}

1;
