package Bio::EnsEMBL::Analysis::Runnable;

use strict;
#use warnings;

use Bio::SeqIO;

use Bio::EnsEMBL::Utils::Exception qw(verbose throw warning);
use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Bio::EnsEMBL::Analysis::Tools::Utilities qw(create_file_name write_seqfile);



=head2 new

    Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
    Arg [2]   : string, name/path of program
    Arg [3]   : string commandline options for the program
    Arg [4]   : string path to working dir 
    Arg [5]   : string, path to bin dir
    Arg [6]   : string, path to libary dir
    Arg [7]   : string, path to data dir
    Function  : create a new Bio::EnsEMBL::Analysis::Runnable
    Returntype: Bio::EnsEMBL::Analysis::Runnable
    Example   : Bio::EnsEMBL::Analysis::Blast->new(
      -query    => $self->query,
      -program  => $self->analysis->program_file,
      $self->parameters_hash,
    );

=cut

sub new {
  my ($class, @args) = @_;
  my $self = bless {}, $class;
  my ($query, $program, $options,
     $workdir, $bindir, $libdir,
     $datadir, $analysis) = rearrange
        (['QUERY', 'PROGRAM', 'OPTIONS',
          'WORKDIR', 'BINDIR', 'LIBDIR',
          'DATADIR', 'ANALYSIS'], @args);
  if(!$analysis){
    throw("Can't create a Runnable without an analysis object");
  } 
  $self->query($query);
  $self->options($options);
  $self->workdir($workdir);
  $self->bindir($bindir);
  $self->datadir($datadir);
  $self->program($program);
  $self->analysis($analysis);

  return $self;
}


#containers

=head2 containers

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string
  Function  : container for specified variable. This pod refers to the
  three methods below options, bindir and datadir. These are simple 
  containers which dont do more than hold and return a given value
  Returntype: string
  Exceptions: none
  Example   : my $options = $self->options;

=cut


sub options {
  my $self = shift;
  $self->{'options'} = shift if(@_);
  return $self->{'options'} || '';
}

sub bindir {
  my $self = shift;
  $self->{'bindir'} = shift if(@_);
  return $self->{'bindir'};
}

sub datadir {
  my $self = shift;
  $self->{'datadir'} = shift if(@_);
  return $self->{'datadir'};
}

=head2 workdir

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, path to working directory
  Arg [3]   : (optional) boolean overwrite existing workdir
  Function  : If given a working directory which doesnt exist
  it will be created by as standard it default to the directory
  specified in General.pm and then to /tmp
  Returntype: string, directory
  Exceptions: none
  Example   : 

=cut

sub workdir {
  my $self = shift;
  my $workdir = shift;
  my $overwrite = shift;  
  if($workdir){
    if(!$self->{'workdir'} || ($overwrite && $overwrite == 1)){
     system("mkdir -p $workdir") unless (-d $workdir);
    }
    $self->{'workdir'} = $workdir;
  } 
  return $self->{'workdir'} ||'/tmp';
}



=head2 query

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : Bio::EnsEMBL::Slice
  Function  : container for the query sequence
  Returntype: Bio::EnsEMBL::Slice
  Exceptions: throws if passed an object which isnt a slice
  Example   : 

=cut


sub query {
  my $self = shift;
  my $slice = shift;
  if($slice){ 
    throw("Must pass Runnable::query a Bio::Seq not a ".
          $slice) unless($slice->isa('Bio::Seq'));
    $self->{'query'} = $slice;
  }
  return $self->{'query'};
}

=head2 program

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, path to program
  Function  : uses locate_executable to find the path of the executable
  Returntype: string, path to program
  Exceptions: throws if program path isnt executable
  Example   : 

=cut



sub program {
  my $self = shift;
  my $program = shift;
  if($program){
    my $path = $self->locate_executable($program);
    $self->{'program'} = $path;
  }
  die($self->{'program'}." is not executable")
    if($self->{'program'} && !(-x $self->{'program'}));
  return $self->{'program'};
}


=head2 analysis

  Arg [1]   : Bio::EnsEMBL::Analysis::RunnableDB
  Arg [2]   : Bio::EnsEMBL::Analysis
  Function  : container for analysis object
  Returntype: Bio::EnsEMBL::Analysis
  Exceptions: throws passed incorrect object type
  Example   : 

=cut



sub analysis {
  my $self = shift;
  my $analysis = shift;
  if($analysis){
    throw("Must pass RunnableDB:analysis a Bio::EnsEMBL::Analysis".
          "not a ".$analysis) unless($analysis->isa
                                     ('Bio::EnsEMBL::Analysis'));
    $self->{'analysis'} = $analysis;
  }
  return $self->{'analysis'};
}

=head2 files_to_delete/protect

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, file name
  Function  : both these methods create a hash keyed on file name the
  first a list of files to delete, the second a list of files to protect
  Returntype: hashref
  Exceptions: none
  Example   : 

=cut

sub files_to_delete {
  my ($self, $file) = @_;
  if(!$self->{'del_list'}){
    $self->{'del_list'} = {};
  }
  if($file){
    $self->{'del_list'}->{$file} = 1;
  }
  return $self->{'del_list'};
}

sub files_to_protect {
  my ($self, $file) = @_;
  if(!$self->{'protect_list'}){
    $self->{'protect_list'} = {};
  }
  if($file){
    $self->{'protect_list'}->{$file} = 1;
  }
  return $self->{'protect_list'};
}

=head2 queryfile

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, filename
  Function  : will hold a given filename or if one is requested but none
  defined it will use the create_filename method to create a filename
  if the resultsfile name hasnt yet been defined it will set that to be
  queryfilename.out
  Returntype: string, filename
  Exceptions: none
  Example   : 

=cut


sub queryfile {
  my ($self, $filename) = @_;

  if($filename){
    $self->{'queryfile'} = $filename;
  }
  if(!$self->{'queryfile'}){
    $self->{'queryfile'} = $self->create_filename('seq', 'fa');
  }
  if(!$self->resultsfile){
    my $resultsfile = $self->{'queryfile'}.".out";
    $self->resultsfile($resultsfile);
  }
  return $self->{'queryfile'};
}


=head2 resultsfile

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, file name
  Function  : container for the results filename
  Returntype: string
  Exceptions: none
  Example   : 

=cut


sub resultsfile {
  my ($self, $filename) = @_;
  if($filename){
    $self->{'resultsfile'} = $filename;
  }
  return $self->{'resultsfile'};
}


#utility methods 

=head2 create_filename

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, stem of filename
  Arg [3]   : string, extension of filename
  Arg [4]   : directory file should live in
  Function  : create a filename containing the PID and a random number
  with the specified directory, stem and extension
  Returntype: string, filename
  Exceptions: throw if directory specifed doesnt exist
  Example   : my $queryfile = $self->create_filename('seq', 'fa');

=cut

sub create_filename {
  my ($self, $stem, $ext, $dir) = @_;
  if(!$dir){
    $dir = $self->workdir;
  } 
  $stem = '' if(!$stem);
  $ext = '' if(!$ext);
  throw($dir." doesn't exist Runnable:create_filename") unless(-d $dir);
  my $num = int(rand(100000));
  my $file = $dir."/".$stem.".".$$.".".$num.".".$ext;
  while(-e $file){
    $num = int(rand(100000));
    $file = $dir."/".$stem.".".$$.".".$num.".".$ext;
  }
  return $file;
}


=head2 locate_executable

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, program name
  Function  : first checks if the passed in name is executable, if not
  checks if the name catted with the bindir is executable, if not
  then uses Bio::EnsEMBL::Analysis::Programs to find where the program
  is
  Returntype: full path of program 
  Exceptions: throws if no name of program is passed in
  Example   : 

=cut


sub locate_executable {
  my ($self, $name) = @_;

  my $path;
  if($name){ 
    if(-x $name){
      $path = $name;
    }elsif($self->bindir && -x $self->bindir."/$name"){
      $path = $self->bindir."/$name";
    }
  }else{
    throw("Must pass Runnable:locate_executable a name if the program ".
          "is to be located");
  }
  return $path;
}

=head2 write_seq_file

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : Bio::Seq
  Arg [3]   : filename
  Function  : This uses Bio::SeqIO to dump a sequence to a fasta file
  Returntype: string, filename
  Exceptions: throw if failed to write sequence
  Example   : 

=cut


sub write_seq_file {
  my ($self, $seq, $filename) = @_;

  if(!$seq){
    $seq = $self->query;
  }
  if(!$filename){
    $filename = $self->queryfile;
  }
  $filename = write_seqfile($seq, $filename);
  return $filename;
}

=head2 checkdir

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, directory
  Arg [3]   : int, space limit
  Function  : check if specified directory has enough space and then
  changes into that directory
  Returntype: none
  Exceptions: throws if not enough diskspace or if cant change into 
  specified directory
  Example   : 

=cut


sub checkdir {
  my ($self, $dir, $spacelimit) = @_;
  if(!$dir){
    $dir = $self->workdir;
  }
  if(!$spacelimit){
    $spacelimit = 0.01;
  }
  throw("Not enough diskspace on ".$dir." RunnableDB:checkdir")
    unless($self->diskspace($dir, $spacelimit));
  chdir($dir) or throw("FAILED to open ".$dir." Runnable::checkdir");
}


=head2 diskspace

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, directory
  Arg [3]   : int, space limit
  Function  : checks how much space is availible in the specified 
  directory using df -kP 
  Returntype: int, binary toggle, returns 0 if not enough space, 1 if 
  there is
  Exceptions: opens DF using a pipe throws if failed to open or close
  that pipe
  Example   : 

=cut


sub diskspace {
  my ($self, $dir, $limit) =@_;
  my $block_size; #could be used where block size != 512 ?
  my $Gb = 1024 ** 3;

  open DF, "df -kP $dir |" || throw("FAILED to open 'df' pipe ".
                                   "Runnable::diskspace : $!\n");
  my $count = 0;
  my $status = 1;
  while (<DF>) {
    if($count && $count > 0){
      my @values = split;
      my $space_in_Gb = $values[3] * 1024 / $Gb;
      $status = 0 if ($space_in_Gb < $limit);
    }
    $count++;
  }
  close DF || throw("FAILED to close 'df' pipe ".
                    "Runnable::diskspace : $!\n");
  return $status;
} 

=head2 run

  Arg [1]   : Bio::EnsEMBL::Analysis::Runnable
  Arg [2]   : string, directory
  Function  : a generic run method. This checks the directory specifed
  to run it, write the query sequence to file, marks the query sequence
  file and results file for deletion, runs the analysis parses the 
  results and deletes any files
  Returntype: 1
  Exceptions: throws if no query sequence is specified
  Example   : 

=cut


sub run {
  my ($self, $dir) = @_;
  $self->workdir($dir) if($dir);
  throw("Can't run ".$self." without a query sequence")
    unless($self->query);
  $self->checkdir();
  my $filename = $self->write_seq_file();
  $self->files_to_delete($filename);
  $self->files_to_delete($self->resultsfile);
  $self->run_analysis();
  return 1;
}




1;


