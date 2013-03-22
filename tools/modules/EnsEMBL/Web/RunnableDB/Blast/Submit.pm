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
}

sub run {
  my $self = shift;

  # Set up the job
  my $workdir = $self->workdir;
  my $db = $self->database; 
  my $query_file = $self->query_file('seq','fa'); 
  my $results_file = $self->results_file;
  my $program = $self->program($self->param('method'));
  my $seqs = $self->param('seqs');
  my $filename = $self->write_seqfile($seqs, $query_file);
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
    system $command;
  }
  else {
    my $command = "$program -p blastn -d $db -i $query_file -o $results_file";
    system $command;
  }
 
   return;
}

sub write_output {
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
  throw("Valid BLAST database could not be inferred from ". $self->param('database'));
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
