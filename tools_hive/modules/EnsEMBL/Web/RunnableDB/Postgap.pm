=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2019] EMBL-European Bioinformatics Institute

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
use Scalar::Util qw(looks_like_number);




sub fetch_input {

  my $self = shift;

  #get parameters
  my $summary_stats = $self->param_required('summary_stats');
  my $output_format = $self->param_required('output_format');
  my $output_dir = $self->param_required('output_dir');
  my $database_dir = $self->param_required('database_dir');
  my $hdf5_file = $self->param_required('hdf5');
  my $sqlite_file = $self->param_required('sqlite');
  my $html_template = $self->param_required('html_template');

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

  #check if html template file exixts
  if (!-f $html_template){
    throw exception('HiveException', "'html_template': file not found.");
  }

}

sub run {

  my $self = shift;

  #get parameters
  my $summary_stats = $self->param('summary_stats');
  my $output_format = $self->param('output_format');
  my $output_dir = $self->param('output_dir');
  my $database_dir = $self->param('database_dir');
  my $hdf5_file = $self->param('hdf5');
  my $sqlite_file = $self->param('sqlite');
  my $html_template = $self->param('html_template');


  my $last_char = chop($output_dir);
  if ($last_char ne "/"){
    $output_dir .=$last_char;
  }
  $output_dir .= '/';

  my $output_file = $output_dir.'output.'.$output_format;
  my $output2_file = $output_dir.'output2.tsv';
  my $report_file = $output_dir.'colocalization_report.html';


  #assign postgap arguments
  my $postgap_arguments = '--summary_stats '. $summary_stats . ' --output '. $output_file . ' --database_dir '. $database_dir . ' --hdf5 ' . $hdf5_file 
                  . ' --sqlite ' . $sqlite_file . ' --output2 '.$output2_file;

  if ($output_format eq 'json'){
    $postgap_arguments .= ' --json_output';
  }

  #call postgap
  my $postgap_command = 'POSTGAP.py ' . $postgap_arguments;
  my $postgap_ret = system($postgap_command);

  #call report
  my $report_arguments = ' --output ' . $report_file . ' --result_file '.$output2_file . ' --template ' . $html_template;
  my $report_command = 'postgap_html_report.py ' . $report_arguments;
  my $report_ret = system($report_command);
  
  return 1;
}

sub write_output {

}

sub _check_format_summary_stats{
  my $self = shift;
  my $summary_stats = $self->param_required('summary_stats');
  my $exception_description = "";


  if (open(my $fh, "<", $summary_stats)){
    my $row_number = 1;
    while (my $row = <$fh>) {
      chomp $row;
      my @line = split ("\t+", $row);
      my $number_of_columns = scalar(@line);

      #check number of columns
      if ($number_of_columns != 8){
        $exception_description = "'summary_stats' line($row_number): wrong number of columns.";
        return $exception_description;
      }

      #skip titles
      next if (uc $line[0] eq 'CHROMOSOME' && $row_number == 1);

      #Chromosome must Not be empty
      if ($line[0] eq "") {
        $exception_description = "'summary_stats' line($row_number): 'Chromosome' must Not be empty.";
        return $exception_description;
      }

      #Position column must be numeric
      if (!looks_like_number($line[1])) {
        $exception_description = "'summary_stats' line($row_number): 'Position' must be a numeric value.";
        return $exception_description;
      }

      #MarkerName must Not be empty
      if ($line[2] eq ""){
        $exception_description = "'summary_stats' line($row_number): 'MarkerName' must Not be empty.";
        return $exception_description;
      }

      #Effect_allele must Not be empty
      if ($line[3] eq ""){
        $exception_description = "'summary_stats' line($row_number): 'Effect_allele' must Not be empty.";
        return $exception_description;
      }

      #Non_Effect_allele must Not be empty
      if ($line[4] eq ""){
        $exception_description = "'summary_stats' line($row_number): 'Non_Effect_allele' must Not be empty.";
        return $exception_description;
      }

      #Beta column must be numeric
      if (!looks_like_number($line[5])) {
        $exception_description = "'summary_stats' line($row_number): 'Beta' must be a numeric value.";
        return $exception_description;
      }

      #SE column must be numeric
      if (!looks_like_number($line[6])) {
        $exception_description = "'summary_stats' line($row_number): 'SE' must be a numeric value.";
        return $exception_description;
      }
      #Pvalue column must be numeric
      if (!looks_like_number($line[7])) {
        $exception_description = "'summary_stats' line($row_number): 'Pvalue' must be a numeric value.";
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



