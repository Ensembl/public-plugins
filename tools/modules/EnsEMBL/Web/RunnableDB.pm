package EnsEMBL::Web::RunnableDB;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(Bio::EnsEMBL::Hive::Process);

use File::Path;
use Bio::Seq;
use Bio::SeqIO;

sub workdir {
 my $self = shift;
 my $workdir = $self->param('work_dir') ."/" . substr($self->param('ticket_name'), 0, 6) ."/" . substr($self->param('ticket_name'), 6);
 mkpath($workdir) unless -d $workdir;
 return $workdir;
}

sub query_file {
  my ($self, $prefix, $extension, $filename)  = @_;

  return $self->param('query_file') if $self->param('query_file');

  if ($filename) {
    $self->param('query_file', $filename);
  }
  if (!$self->param('query_file')) {
    $self->param('query_file', $self->create_filename($prefix, $extension));
  }
  if(!$self->results_file){
    my $results_file = $self->param('query_file').".out";
    $self->results_file($results_file);
  }
  return $self->param('query_file');
}

sub results_file {
  my ($self, $filename) = @_;
  if($filename){
    $self->param('results_file', $filename);
  }
  return $self->param('results_file');
}

sub create_filename {
  my ($self, $stem, $ext, $dir) = @_;
  if(!$dir){
    $dir = $self->workdir;
  }
  $stem = '' if(!$stem);
  $ext = '' if(!$ext);
  my $numeric_id = $self->param('ticket') . $self->{_input_job}->dbID; 
  throw($dir." doesn't exist Runnable:create_filename") unless(-d $dir);
  my $file = $dir ."/". $numeric_id .".". $stem .".". $ext;
  return $file;
}

sub program {
  my $self = shift;  
  my $program = shift; 

  if($program){
    my $path = $self->locate_executable($program);
    $self->param('valid_program', $path);
  }

    if($self->param('valid_program') && !(-x $self->param('valid_program'))){
      die $self->param('valid_program')." is not executable"      
    }

  return $self->param('valid_program');
}

sub locate_executable {
  my ($self, $name) = @_;

  my $path; 
  if($name){
    if(-x $name) {
      $path = $name;  
    } elsif ($self->bindir  && -x $self->bindir ."/$name") {
      $path = $self->param('bindir')."/$name";
    } else {
      die $name ." program can not be found.";
    }
  }else {  
    die "No program was specified";
  } 
  return $path;
}

sub bindir {
  my $self = shift;
  $self->param('bindir', $self->param('bin_dir'));
  return $self->param('bindir')
}

sub write_seqfile{
  my ($self, $seqs, $filename, $format) = @_;
  $format = 'fasta' if(!$format);

  $filename = create_file_name('seq', 'fa', '/tmp') if(!$filename);
  my $seqout = Bio::SeqIO->new(
                               -file => ">".$filename,
                               -format => $format,
                              );

  foreach my $id ( keys %{$seqs}){
    my $seq = $seqs->{$id};
    my $bioperl_seq = Bio::Seq->new( -seq => $seq, -id =>$id);
    eval{
      $seqout->write_seq($bioperl_seq);
    };
    if($@){
      #throw("FAILED to write $seq to $filename SequenceUtils:write_seq_file $@");
    }
  }
  return $filename;
}
1;
