package Bio::EnsEMBL::Analysis::Runnable::Blast;

use strict;
#use warnings;

use Bio::EnsEMBL::Utils::Exception qw(throw warning info);
use Bio::EnsEMBL::Utils::Argument qw( rearrange );

use base qw(Bio::EnsEMBL::Analysis::Runnable);

sub new {
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);
  my ($database, $type,
      $unknown_error, $ticket_name ) = rearrange(['DATABASE',
                                    'TYPE', 'UNKNOWN_ERROR_STRING',
                                    'TICKET',      
                                   ], @args);

  $ticket_name = undef unless($ticket_name);  
  $type = undef unless($type);
  $unknown_error = undef unless($unknown_error);
  ######################
  #SETTING THE DEFAULTS#
  ######################
  $self->type('ncbi');
  $self->unknown_error_string('FAILED');
  $self->options('-cpus=1') if(!$self->options);
  ######################
  $self->databases($database);
  $self->ticket_name($ticket_name);
  $self->type($type) if($type);
  $self->unknown_error_string($unknown_error) if($unknown_error);

  throw("No valid databases to search")
    unless(@{$self->databases});
  
  return $self;

}

sub databases {
   my ($self, @vals) = @_;

  if (not exists $self->{databases}) {
    $self->{databases} = [];
  }

  foreach my $val (@vals) {
    my $dbname = $val;

    my @dbs;

    $dbname =~ s/\s//g;

    # prepend the environment variable $BLASTDB if
    # database name is not an absoloute path

    unless ($dbname =~ m!^/!) {
      $dbname = $ENV{BLASTDB} . "/" . $dbname;
    }

    # If the expanded database name exists put this in
    # the database array.
    #
    # If it doesn't exist then see if $database-1,$database-2 exist
    # and put them in the database array

#    if (-f $dbname) {
      push(@dbs,$dbname);
#    } else {
#      my $count = 1;
#      while (-f $dbname . "-$count") {
#        push(@dbs,$dbname . "-$count");    
#        $count++;    
#      }
#    }

    if (not @dbs) {
      warning("Valid BLAST database could not be inferred from '$val'");
    } else {
      push @{$self->{databases}}, @dbs;
    }
  }

  return $self->{databases};
}

sub ticket_name {
  my $self = shift; 
  my $ticket_name = shift if (@_);
  if ($ticket_name && $ticket_name =~/^BLA/){ 
    if (!$self->{'ticket_name'}){ 
      $self->{'ticket_name'} = $ticket_name
    }
  } 
  return $self->{'ticket_name'};
}

sub type {
  my $self = shift;
  $self->{'type'} = shift if(@_);
  return $self->{'type'};
}

sub unknown_error_string{
  my $self = shift;
  $self->{'unknown_error_string'} = shift if(@_);
  return $self->{'unknown_error_string'};
}

sub queryfile {
  my ($self, $filename) = @_;
  my $dir = $self->workdir ."/" . substr($self->ticket_name, 0, 6) . "/" . substr($self->ticket_name, 6);
  $self->workdir($dir, 1);  

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


sub run_analysis {
  my ($self) = @_;

  foreach my $database (@{$self->databases}) {

    my $db = $database;
    $db =~ s/.*\///;
    #allow system call to adapt to using ncbi blastall. 
    #defaults to WU blast
    my $command  = $self->program; 
    my $filename = $self->queryfile;
    my $results_file = $self->resultsfile;
    if ($self->type eq 'ncbi') { my $method = 'blastn';
      $command .= " -p $method -d $database -i $filename ";
    } else {
      $command .= " $database $filename -gi ";
    }
      $command .=  ' -o ' .$results_file;

    print  "Running blast ".$command."\n";
    info("Running blast ".$command);
  open(my $fh, "$command |") ||
      throw("Error opening Blast cmd <$command>." .
            " Returned error $? BLAST EXIT: '" .
            ($? >> 8) . "'," ." SIGNAL '" . ($? & 127) .
            "', There was " . ($? & 128 ? 'a' : 'no') .
            " core dump");


  }
}

1;
