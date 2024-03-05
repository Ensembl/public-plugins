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

package EnsEMBL::Web::RunnableDB::Blast;

### Hive Process RunnableDB for BLAST

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Utils::DynamicLoader qw(dynamic_require);

use parent qw(EnsEMBL::Web::RunnableDB);

## STEP 1
## Fetch input : Set up all the required parameters, directories, file names etc and do required validations
sub fetch_input {
  my $self        = shift;
  my $blast_type  = $self->param_required('blast_type');

  $self->setup_iofiles($blast_type);
  $self->setup_executables($blast_type);
  $self->setup_source_file($blast_type);

  # Other required params
  $self->param_required($_) for qw(job_id ticket_db);

  return 1;
}

## STEP 1.1
## Setup IO files
sub setup_iofiles {
  my ($self, $blast_type) = @_;

  my $work_dir    = $self->work_dir;
  my $sequence    = $self->param_required('sequence');
  my $input_file  = sprintf '%s/%s', $work_dir, $sequence->{'input_file'};
  my $output_file = sprintf '%s/%s', $work_dir, $self->param_required('output_file');

  # Input file
  throw exception('HiveException', 'Input file could not be found.') unless -f $input_file && -r $input_file;

  # Setup the files names
  $self->param('__query_file',    "$input_file");
  $self->param('__results_raw',   "$output_file");
  $self->param('__results_file',  "$output_file.unformatted");
  $self->param('__results_tab',   "$output_file.tab");
}

## STEP 1.2
## Setup executable files
sub setup_executables {
  my ($self, $blast_type) = @_;

  my $bin_dir = $self->param_required("${blast_type}_bin_dir");
  my $program = $self->param_required('program');

  throw exception('HiveException', 'Directory containing the executable file could not be found.')                  unless -d $bin_dir;
  throw exception('HiveException', 'Executable file for running the job could not be found, or is not accessible.') unless -x "$bin_dir/$program";
  throw exception('HiveException', 'Reformatter executable file could not be found, or is not accessible.')         unless -x "$bin_dir/blast_formatter";
  $self->param('__program_file',      "$bin_dir/$program");
  $self->param('__reformat_program',  "$bin_dir/blast_formatter");

  # Setup the repeat masker bin file if required
  my $configs = $self->param_is_defined('configs') && $self->param('configs') || {};
  if ($configs->{'repeat_mask'} eq 'yes') {
    my $rm_binary = $self->param_required("${blast_type}_repeat_mask_bin");
    throw exception('HiveException', 'RepeatMasking executable file is either missing or not accessible.') unless -x $rm_binary;
    $self->param('__repeat_mask_bin', $rm_binary);
  }
}

## STEP 1.3
## Setup source file
sub setup_source_file {
  my ($self, $blast_type) = @_;

  my $species     = $self->param_required('species');
  my $source_type = $self->param_required('source');
  my $query_type  = $self->param_required('query_type');
  my $source_dir  = $self->param_required($source_type =~ /LATESTGP/ ? 'dna_index_files' : 'index_files');
  my $source_file = $self->param_required('source_file');

  # Setup the data files name
  throw exception('HiveException', "Directory containing the '$source_type' source files could not be found. $source_dir")  unless opendir SOURCE_DIR, $source_dir;
  throw exception('HiveException', "Required source file $source_file is missing for $species")                             unless grep { !-d && m/^$source_file/ } readdir SOURCE_DIR;
  $self->param('__source_file', "$source_dir/$source_file");
  closedir SOURCE_DIR;
}

## STEP 2
## Run: Run the actual blast program to get the results saved in the results file
sub run {
  my $self = shift;

  # Set up the job
  my $source_file   = $self->param('__source_file');
  my $query_file    = $self->param('__query_file');
  my $results_file  = $self->param('__results_file');
  my $raw_output    = $self->param('__results_raw');
  my $tab_output    = $self->param('__results_tab');
  my $program       = $self->param('__program_file');
  my $reformatter   = $self->param('__reformat_program');
  my $rm_binary     = $self->param_is_defined('__repeat_mask_bin') ? $self->param('__repeat_mask_bin') : '';
  my $configs       = $self->param_is_defined('configs') ? $self->param('configs') : {};

  # Retain the 'max number of hits' param for limiting the number of returned hits by the blast script
  # Keep the max_target_seqs too for the blast script to use it to limit the number of target sequences
  $self->param('__max_hits', $configs->{'max_target_seqs'} || 0);

  # RepeatMasking needed?
  if (delete $configs->{'repeat_mask'} eq 'yes') {

    $query_file =~ /(^.+\/)([^\/]+$)/;
    my $repeatmasker_command = EnsEMBL::Web::SystemCommand->new($self, "perl $rm_binary", [ '-dir', $1, $2 ], undef, undef, $self->work_dir)->execute({'log_file' => "$results_file.repeatmask.log"});
    # remove the unwanted RepeatMasker's output file
    unlink "$query_file.$_" for qw(tbl cat);

    # Point to a different input file if RepeatMarker got some output
    $query_file = "$query_file.masked" if -s "$query_file.masked";
  }

  # Run the blast process
  my $blast_log     = "$results_file.log";
  my $blast_command = EnsEMBL::Web::SystemCommand->new($self, $program, {
    '-db'       => $source_file,
    '-query'    => $query_file,
    '-out'      => $results_file,
    '-outfmt'   => 11,
    map {("-$_" => $configs->{$_})} keys %$configs
  }, {
    '1'   => 'Error in query sequence(s) or BLAST options',
    '2'   => 'Error in BLAST database',
    '3'   => 'Error in BLAST engine',
    '4'   => 'Out of memory',
    '139' => 'Out of memory'
  })->execute({'log_file' => $blast_log});

  # Throw exception if any error occurred during running the blast process
  if (my $error_code = $blast_command->error_code) {
    my $error_message = $blast_command->error_message;
    my ($error_details) = file_get_contents($blast_log);
    throw exception('HiveException', $error_code == 1
      ? ($error_message, {'display_message' => $error_details, 'fatal' => 0}) # input error -  user needs to change input sequence or configs
      : ($error_details || $error_message)                                    # system error - user can't do anything
    );
  }

  # Generate the raw output file (this file is not processed further but is only downloaded by the user)
  my $raw_log     = "$raw_output.log";
  my $raw_command = EnsEMBL::Web::SystemCommand->new($self, $reformatter, [
    '-archive'  => $results_file,
    '-out'      => $raw_output
  ])->execute({'log_file' => $raw_log});

  # Throw exception if reformatter fails
  if (my $error_code = $raw_command->error_code) {
    my ($error_details) = file_get_contents($raw_log);
    throw exception('HiveException', $error_details);
  }

  # Generate the tabular output file for display purposes
  my $tab_log     = "$tab_output.log";
  my $tab_options = '"6 qseqid qstart qend sseqid sstart send bitscore evalue pident length btop qframe sframe"';
  my $tab_command = EnsEMBL::Web::SystemCommand->new($self, $reformatter, [
    '-archive'  => $results_file,
    '-out'      => $tab_output,
    '-outfmt'   => $tab_options
  ])->execute({'log_file' => $tab_log});

  # Throw exception if reformatter fails
  if (my $error_code = $tab_command->error_code) {
    my ($error_details) = file_get_contents($tab_log);
    throw exception('HiveException', $error_details);
  }

  # Remove the unformatted file to free up the space
  try {
    unlink $results_file;
  } catch {};

  return 1;
}

## STEP 3
## Now since all output files have been generated by the blast programs, save the results in the tickets database
sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $blast_type  = $self->param('blast_type');
  my $result_file = $self->param('__results_tab');
  my $module;
  try {
    $module = dynamic_require("EnsEMBL::Web::Parsers::$blast_type");
  } catch {
    throw exception('HiveException', $_->message(1));
  };

  $self->save_results($job_id, {}, $module->new($self)->parse($result_file));

  return 1;
}

1;
