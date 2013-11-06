package EnsEMBL::Web::RunnableDB::Blast::Submit;

### Hive Process RunnableDB for BLAST

use strict;
use warnings;

use base qw(EnsEMBL::Web::RunnableDB);

use File::Path;
use DBI;

use Bio::Seq;
use Bio::SeqIO;

use EnsEMBL::Web::Parsers::NCBIBlast;
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Tools::FileHandler qw(file_get_contents);

## STEP 1
## Setup : Set up all the required parameters, directories, file names etc and do requreid validations
sub setup {
  my $self = shift;

  my $job_id      = $self->param_required('job_id');
  my $ticket_name = $self->param_required('ticket_name');
  my $species     = $self->param_required('species');
  my $blast_type  = $self->param_required('blast_type');
  my $work_dir    = $self->param_required("${blast_type}_work_dir");
  my $bin_dir     = $self->param_required("${blast_type}_bin_dir");
  my $program     = $self->param_required('program');
  my $source_type = $self->param_required('source');
  my $query_type  = $self->param_required('query_type');
  my $dba         = $self->param_required('dba');
  my $ticket_dbc  = $self->param_required('ticket_db');
  my $sequence    = $self->param_required('sequence');
  my $source_dir  = $self->param_required(sprintf '%s%s_index_files', $blast_type, $source_type =~ /LATESTGP/ ? '_dna' : '');
  my $source_file = $self->param_required('source_file');

  # Setup the work directory
  throw exception('HiveException', 'Work directory could not be found.') unless -d $work_dir;
  $work_dir = join('/', $work_dir, ($ticket_name =~ /.{1,6}/g)) =~ s/\/+/\//gr;
  mkpath($work_dir) unless -d $work_dir;
  $self->param('__work_dir', $work_dir);

  # Setup the files names
  my $file_name = sprintf '%s/%s.%s', $work_dir, $job_id, $self->input_job->dbID;
  $self->param('__query_file',    "$file_name.query");
  $self->param('__results_file',  "$file_name.out");
  $self->param('__results_raw',   "$file_name.out.raw");
  $self->param('__results_tab',   "$file_name.out.tab");

  # Setup the actual command line executable file
  throw exception('HiveException', 'Directory containing the executable file could not be found.')                  unless -d $bin_dir;
  throw exception('HiveException', 'Executable file for running the job could not be found, or is not accessible.') unless -x "$bin_dir/$program";
  throw exception('HiveException', 'Reformatter executable file could not be found, or is not accessible.')         unless -x "$bin_dir/blast_formatter";
  $self->param('__program_file',      "$bin_dir/$program");
  $self->param('__reformat_program',  "$bin_dir/blast_formatter");

  # Setup the data files name
  throw exception('HiveException', "Directory containing the '$source_type' source files could not be found. $source_dir")      unless opendir SOURCE_DIR, $source_dir;
  throw exception('HiveException', "Required source file $source_file is missing for $species")                     unless grep { !-d && m/^$source_file/ } readdir SOURCE_DIR;
  $self->param('__source_file', "$source_dir/$source_file");
  closedir SOURCE_DIR;

  # Setup the repeat masker bin file if required
  my $configs = $self->param('configs') || {};
  if ($configs->{'repeat_mask'}) {
    my $rm_binary = $self->param_required("${blast_type}_repeat_mask_bin");
    throw exception('HiveException', 'RepeatMasking executable file is either missing or not accessible.') unless -x $rm_binary;
    $self->param('__repeat_mask_bin', $rm_binary);
  }
}

## STEP 2
## Fetch input : Get the actual input and save into the required files for processing
sub fetch_input {
  my $self = shift;

  # Do the initial setup (Setup is not included in hive lifecycle, so will have to call it here)
  $self->setup;

  # Write the input sequence to the query file
  my $sequence    = $self->param('sequence');
  my $query_type  = $self->param('query_type');
  my $query_file  = $self->param('__query_file');
  my $seq_out     = Bio::SeqIO->new(
    '-file'         => ">$query_file",
    '-format'       => 'fasta'
  );
  my $bio_seq     = Bio::Seq->new(
    '-id'           => $sequence->{'display_id'},
    '-seq'          => $sequence->{'seq'},
    '-alphabet'     => $query_type eq 'dna' ? 'dna' : 'protein'
  );
  my $error;
  try {
    $seq_out->write_seq($bio_seq);
  } catch {
    $error = $_;
  };
  throw exception('HiveException', "Bio::Seq could not write_seq: $sequence->{'seq'}, failed with error: $error") if $error;

  return 1;
}

## STEP 3
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

  # RepeatMasking needed?
  if (delete $configs->{'repeat_mask'}) {

    $query_file =~ /(^.+\/)([^\/]+$)/;
    my $repeatmasker_command = EnsEMBL::Web::SystemCommand->new($self, $rm_binary, [ '-dir', $1, $2 ])->execute({'log_file' => "$query_file.masked.log"});

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
    '255' => 'Unknown error'
  })->execute({'log_file' => $blast_log});

  # Throw exception if any error occurred during running the blast process
  if (my $error_code = $blast_command->error_code) {
    my $error_message = $blast_command->error_message;
    my ($error_details) = file_get_contents($blast_log);
    throw exception('HiveException', $error_code == 1
      ? ($error_message, {'display_message' => $error_details, 'fatal' => 0}) # input error -  user needs to change input sequence or configs
      : ($error_details)                                                      # system error - user can't do anything
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

  return 1;
}

## STEP 4
## Now since all output files have been generated by the blast programs, save the results in the tickets database
sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $results     = EnsEMBL::Web::Parsers::NCBIBlast->new($self)->parse;

  $self->save_results($job_id, $results);
}

1;
