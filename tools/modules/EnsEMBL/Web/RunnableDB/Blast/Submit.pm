package EnsEMBL::Web::RunnableDB::Blast::Submit;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::RunnableDB);
use EnsEMBL::Web::Parsers::NcbiBlast;

sub fetch_input {
  my $self = shift;
  my $ticket_id = $self->param('ticket');

  return;    
 #$self->param  retrieves data the input_id hashref from job object, or from the params in the PipeConfig file for this analysis 
}

sub run {
  my $self = shift;

  # Set up the job
  my $workdir = $self->workdir;
  my $db = $self->database; 
  my $query_file = $self->query_file('seq','fa'); 
  my $results_file = $self->results_file;
  my $program = $self->program($self->param('method'));
  my @seqs = values %{$self->param('seqs')};
  my $filename = $self->write_seqfile(\@seqs, $query_file);
  my $type = 'ncbi';
  my $masked = $self->repeat_mask($filename) if $self->param('mask'); 
  $query_file .= ".masked" if $masked;

  my $config = $self->param('config');
  my $option_str = '';
  while ( (my $option, my $value) =  each %$config ){
    next if $option eq 'repeat_mask';
    $option_str .= " -" . $option . " " . $value; 
  }

  # Run the blast process 
  if ($type eq 'ncbi'){
    my $command = "$program -db $db -query $query_file -out $results_file -outfmt 11 $option_str"; 
warn $command;
    system $command;
  }
  else {
    my $command = "$program -p blastn -d $db -i $query_file -o $results_file";
    system $command;
  }
 
   return;
}

sub write_output {
=cut  my $self = shift;
#sleep (40);
  # This will be the parsing step
  my $type = 'ncbi';

  if ($type eq 'ncbi'){
    # First convert the 'archive' blast output format to files we can use

    my $reformat_program = $self->program('blast_formatter');
    my $results_file = $self->results_file;

    my $results_raw = $results_file;
    $results_raw =~s/out/raw/;
    my $raw_format_command = "$reformat_program -archive $results_file -out $results_raw";
    system $raw_format_command;

    my $results_tab = $results_file;
    $results_tab =~s/out/tab/; 
    my $output_options = '"6 qseqid qstart qend sseqid sstart send bitscore evalue pident length btop qframe sframe"';
    my $parse_format_command = "$reformat_program -archive $results_file -out $results_tab -outfmt $output_options";
    system $parse_format_command; 

    my $ticket = $self->param('ticket_name');    
    my $parse_blast_command = $self->param('ensembl_cvs_root_dir') . "/sanger-plugins/tools/utils/parse_ncbi_blast_plus.pl $ticket $results_tab";
    system $parse_blast_command;

  }
=cut

  my $self = shift;
  my $parser = EnsEMBL::Web::Parsers::NcbiBlast->new($self);
  $parser->parse;
  return;
}


######### Private methods ########

sub database {
  my $self = shift;
 
  return $self->param('valid_database') if $self->param('valid_database');

  my $path_to_db = $self->param('query_type') eq 'dna' ? $self->param('blast_dna_index_files') : $self->param('blast_index_files');

  my $dbname = $path_to_db .'/'. $self->param('database');

  $dbname =~ s/\s//g;
  # prepend the environment variable $BLASTDB if
  # database name is not an absoloute path

  unless ($dbname =~ m!^/!) {
    $dbname = $ENV{BLASTDB} . "/" . $dbname;
  }

 if (-d $path_to_db){ 
  $self->param('valid_database', $dbname);
 } else { ## error needs passing to hive db
  warning("Valid BLAST database could not be inferred from ". $self->param('database'));
 } 

 return $self->param('valid_database');
}

sub bindir {
  my $self = shift;
  $self->param('bindir', $self->param('blast_bin_dir'));
  return $self->param('bindir')  
}

sub repeat_mask {
  my $self = shift;
  my $filename = shift;
  my $temp = $filename;
  $temp =~s/(\d+\.seq\.fa)/:$1/;
  my ($dir, $file) = split (/:/, $temp);
  my $flag;

  my $command = $self->param('repeatmask_bin_dir') . ' -dir ' . $dir .' ' . $filename;    
  system $command;
 
  my @exts = ('tbl', 'cat'); 
  foreach (@exts){
    my $command = 'rm ' . $filename .'.'. $_;
    system $command;
  }

  if (-s $filename . ".masked") { $flag = 1; }  
  return $flag;
}

1;
