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

package EnsEMBL::Web::RunnableDB::Postgap;

### Hive Process RunnableDB for Postgap Web Tool

use strict;
use warnings;

use parent qw(EnsEMBL::Web::RunnableDB);
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use Scalar::Util qw(looks_like_number);

sub fetch_input {

  my $self = shift;

  #get parameters
  my $summary_stats   = $self->param_required('work_dir').'/'.$self->param_required('input_file');
  my $output_format   = $self->param_required('output_format') || 'tsv';
  my $output_dir      = $self->param_required('work_dir');
  my $database_dir    = $self->param_required('postgap_data_path');
  my $hdf5_file       = $self->param_required('hdf5');
  my $sqlite_file     = $self->param_required('sqlite');
  my $html_template   = $self->param_required('postgap_template_file');
  my $report_script   = $self->param_required('postgaphtml_bin_path');
  my $postgap_script  = $self->param_required('postgap_bin_path');

  #check if summary_stats file exixts
  if (!-f $summary_stats){
    throw exception('HiveException', "'summary_stats': file not found.");
  }

  #check output format
  if ($output_format ne 'tsv' && $output_format ne 'json'){
    throw exception('HiveException', "'output_format': output format should be 'tsv' or 'json'");
  }

  #check output dir 
  if (!-d $output_dir){
    throw exception('HiveException', "'output_dir': path not found.");
  }

  #check database dir
  if (!-d $database_dir){
    throw exception('HiveException', "'database_dir': directory not found.");
  }

  #check if hdf5 file exixts
  if (!-f $hdf5_file){
    throw exception('HiveException', "'hdf5_file': file not found.");
  }

  #check if sqlite file exixts
  if (!-f $sqlite_file){
    throw exception('HiveException', "'sqlite_file': file not found.");
  }

  #check summary_stats file format
  my $check_format_result = $self->_check_format_summary_stats();
  if ($check_format_result ne ''){
    throw exception('HiveException', $check_format_result);
  }
}

sub run {

  my $self = shift;

  #get parameters
  my $summary_stats   = $self->param_required('work_dir').'/'.$self->param_required('input_file');
  my $raw_output_file = $self->param_required('output_file');
  my $population      = $self->param_required('population');
  my $raw_report_file = $self->param_required('report_file');
  my $output_format   = $self->param_required('output_format') || 'tsv';
  my $output_dir      = $self->param_required('work_dir');
  my $raw_output2_file = $self->param_required('output2_file');
  my $database_dir    = $self->param_required('postgap_data_path');
  my $hdf5_file       = $self->param_required('hdf5');
  my $sqlite_file     = $self->param_required('sqlite');
  my $html_template   = $self->param_required('postgap_template_file');
  my $sharedsw_path   = $self->param_required('sharedsw_path');
  my $log_file        = sprintf('%s/postgap.log', $output_dir );

  my $last_char = chop($output_dir);
  if ($last_char ne "/"){
    $output_dir .=$last_char;
  }
  $output_dir .= '/';

  my $output_file = $output_dir.$raw_output_file.'.'.$output_format;
  my $output2_file = $output_dir.$raw_output2_file;
  my $report_file = $output_dir.$raw_report_file;

  my $command = EnsEMBL::Web::SystemCommand->new($self, sprintf('cd %s;python %s ', $output_dir, $self->param('postgap_bin_path')), {
    '--summary_stats' => $summary_stats,
    '--population'    => $population,
    '--output'        => $output_file,
    '--database_dir'  => $database_dir,
    '--hdf5'          => $hdf5_file,
    '--sqlite'        => $sqlite_file,
    '--bayesian'      => '',
    '--output2'       => $output2_file,
  })->execute({
    'log_file'    => $log_file,
  });

#  if ($output_format eq 'json'){
#    $postgap_arguments .= ' --json_output';
#  }
  if($command->error_code) {
    throw exception('HiveException', "Job fail: Error code ".$command->error_code);
  }

  #check if output file was generated
  if (!-f $output_file){
    throw exception('HiveException', "'Output file': Output file missing. It could be that the job fail to finish running.");
  }

  #if output2 file is empty then return (no data found)
  if(-z $output2_file) {
    return 1;
  }  

  #copy template file to work_dir so that it can be written to
  my $cp_cmd = EnsEMBL::Web::SystemCommand->new($self, "cp $html_template $output_dir")->execute();
  throw exception('HiveException', "Error in copying template file: ".$cp_cmd->error_code) if $cp_cmd->error_code;


  #check if output2 file exists before running report
  if (!-f $output2_file){
    throw exception('HiveException', "'Report output file': Output file for generating report not found. It could be that the job fail to finish running.");
  }

  # getting the filename from the path, split on the last /
  my @path_split        = split(/([^\/]+$)/, $html_template);
  my $template_filename = $path_split[1];

  #check if html template file exists
  if (!-f $output_dir.$template_filename){
    throw exception('HiveException', "'html template file': file not found.");
  }  

  # generate html report
  my $report_command = EnsEMBL::Web::SystemCommand->new($self, sprintf('cd %s;python %s ', $output_dir, $self->param('postgaphtml_bin_path')), {
    '--output'       => $report_file,
    '--result_file'  => $output2_file,
    '--template'     => $output_dir.$template_filename,
  })->execute({
    'log_file'    => sprintf('%s/postgap_report.log', $output_dir ),
  });

  ## TODO catch error from command above and any other error

  # compress the outputs
  my $gzip_cmd =  EnsEMBL::Web::SystemCommand->new($self, "cd $output_dir; tar -czvf $raw_output_file.tar.gz $raw_output_file.$output_format $raw_output2_file $raw_report_file --remove-files")->execute();
  if(!$gzip_cmd->error_code) {
    my $trim_file  = $output_dir.$raw_output_file.".tar.gz";
    throw exception('HiveException', "Gzipping error: ".$gzip_cmd->error_code) unless -s $trim_file;
  }

  return 1;
}

sub write_output {

}

sub _check_format_summary_stats{
  my $self = shift;
  my $summary_stats = $self->param_required('work_dir').'/'.$self->param_required('input_file');
  my $exception_description = "";


  if (open(my $fh, "<", $summary_stats)){
    my $row_number = 1;

    #check headers
    my $row = <$fh>;
    $row =~ s/\R//g;
    my @line = split ("\t+", $row);
    
    #check existence of variant_id column
    my ($variant_id_index) = grep { $line[$_] eq 'variant_id' } (0 .. @line-1);
    if (! defined $variant_id_index) {
      $exception_description = "'summary_stats' line($row_number): 'variant_id' column missing.";
      return $exception_description;
    }

    #check existence of beta column
    my ($beta_index) = grep { $line[$_] eq 'beta' } (0 .. @line-1);
    if (! defined $beta_index) {
      $exception_description = "'summary_stats' line($row_number): 'beta' column missing.";
      return $exception_description;
    }

    #check existence of p-value column
    my ($pvalue_index) = grep { $line[$_] eq 'p-value' } (0 .. @line-1);
    if (! defined $pvalue_index) {
      $exception_description = "'summary_stats' line($row_number): 'p-value' column missing.";
      return $exception_description;
    }

    while (my $row = <$fh>) {
      $row =~ s/\R//g;
      my @line = split ("\t+", $row);

      #variant_id must be an rsID
      if ($line[$variant_id_index] !~ /rs\d+/){
        $exception_description = "'summary_stats' line($row_number): 'variant_id' must be an rsID.";
        return $exception_description;
      }

      #beta must be numeric 
      if (!looks_like_number($line[$beta_index])) {
        $exception_description = "'summary_stats' line($row_number): 'beta' must be a numeric value.";
        return $exception_description;
      }

      #p-value column must be numeric between 0 and 1
      if (!looks_like_number($line[$pvalue_index]) || $line[$pvalue_index] < 0 || $line[$pvalue_index] > 1) {
        $exception_description = "'summary_stats' line($row_number): 'p-value' must be a numeric value between 0 and 1.";
        return $exception_description;
      }

      $row_number+=1;
    }


  }else{
    $exception_description = "'summary_stats': can't open file.";
  } 

  return $exception_description;

}

1;



