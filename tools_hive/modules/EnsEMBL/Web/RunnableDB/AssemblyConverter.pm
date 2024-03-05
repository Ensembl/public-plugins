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

package EnsEMBL::Web::RunnableDB::AssemblyConverter;

### Hive Process RunnableDB for CrossMap assembly converter

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::RunnableDB);

sub fetch_input {
  ## @override
  my $self = shift;

  my $ac_bin = $self->param_required('AC_bin_path');

  throw exception('HiveException', 'CrossMap package file is either missing or is not executable.') unless -x $ac_bin;
}

sub run {
  ## @override
  my $self = shift;

  # Set up the job
  my $ac_bin      = $self->param('AC_bin_path');
  my $work_dir    = $self->param('work_dir');
  my $data_dir    = $self->param('data_dir');
  my $config      = $self->param('config');
  my $chain_file  = sprintf('%s/%s', $data_dir, $config->{'chain_file'});
  my $input_file  = sprintf('%s/%s', $work_dir, $config->{'input_file'});
  my $output_file = sprintf('%s/%s', $work_dir, $config->{'output_file'});
  my $extra_path  = $self->param('extra_PATH');
  my $format      = $config->{'format'};
     $format      = 'gff' if $format eq 'gtf'; # CrossMap treats these formats the same

  # arguments for crossmap command
  # crossmap <format> <chain_file> <input> <optional: fasta> <output>
  my @options = (
    $format,
    $chain_file,
    $input_file,
    $format eq 'vcf' ? sprintf('%s/%s', $data_dir, $config->{'fasta_file'}) : (),
    $output_file
  );

  my $log_file    = sprintf('%s/crossmap.log', $work_dir);
  my $ac_command  = EnsEMBL::Web::SystemCommand->new($self, $ac_bin, \@options, {}, [ $extra_path || () ], $work_dir)->execute({'log_file' => $log_file});

  # throw exception if process failed (crossmap prints actual error in the end of the file and anything starting with @ is a verbose information, not error)
  if ($ac_command->error_code) {
    my @error_details = file_get_contents($log_file, sub { chomp; /^\@/ ? undef : $_ });
    throw exception('HiveException', $error_details[-1]);
  }

  # For wig files, crossmap only return bigwig. So we try to convert the output back to wig
  if ($format eq 'wig' && !-e $output_file && -e "$output_file.bw") {
    my $bw_to_w_bin = sprintf('%s/bigWigToWig', $extra_path);
    my $log_file    = sprintf('%s/bigWigToWig.log', $work_dir);
    my $command     = EnsEMBL::Web::SystemCommand->new($self, $bw_to_w_bin, [ "$output_file.bw", $output_file ], {}, [], $work_dir)->execute({'log_file' => $log_file});

    if ($command->error_code) {
      $self->tools_warning({'type' => 'AssemblyConverterWarning', 'message' => 'BigWig output could not be converted into Wig.'});
    }
  }

  return 1;
}

sub write_output {
  my $self              = shift;
  my $job_id            = $self->param('job_id');
  my $work_dir          = $self->param('work_dir');
  my $output_file_path  = sprintf('%s/%s', $work_dir, $self->param('config')->{'output_file'});

  #if there is some results in the output file then 
  if(-s $output_file_path) {
    $self->save_results($job_id, {}, [{"dummy" => "Assembly Converter result"}]); #for now storing dummy results as the output is stored in an output file
  }

  return 1;
}

1;
