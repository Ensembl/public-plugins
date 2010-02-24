=head1 NAME

Bio::Tools::Run::Search::SGE_WuBlast - Base class for Ensembl BLAST searches

=head1 SYNOPSIS

  see Bio::Tools::Run::Search::WuBlast

=head1 DESCRIPTION

An extension of Bio::Tools::Run::Search::WuBlast to cope with a
blast farm usine SGE. E.g. uses the qsub job submission system to
dispatch jobs. The jobs themselves are wrapped in the
utils/runblast.pl perl script.

=cut

# Let the code begin...
package Bio::Tools::Run::Search::SGE_WuBlast;
use strict;
#use File::Copy qw(mv cp);
use File::Copy;
use Data::Dumper qw(Dumper);

use vars qw( @ISA 
	     $QSUB_RESOURCE
	     $MAX_BLAST_CPUS
	     $SPECIES_DEFS );

use Bio::Tools::Run::Search::WuBlast;
use EnsEMBL::Web::RegObj;
use Sys::Hostname qw(hostname);

@ISA = qw( Bio::Tools::Run::Search::WuBlast );

BEGIN{
  $SPECIES_DEFS = $ENSEMBL_WEB_REGISTRY->species_defs;

  $QSUB_RESOURCE = '-l h_rt=10:00:00,s_rt=10:00:00';

  # Set default blast cpus flag for SMP boxes
  $MAX_BLAST_CPUS = 1;
}

#----------------------------------------------------------------------

=head2 run

  Arg [1]   : none
  Function  : Dispatches the blast job using the dispatch_qsub method
  Returntype: 
  Exceptions: 
  Caller    : 
  Example   : 

=cut

sub run {
  my $self = shift;

  if( $self->status ne 'PENDING' and
      $self->status ne 'DISPATCHED' ){
    $self->warn( "Wrong status for run: ". $self->status );
  }

  # Apply environment variables, keeping a backup copy
  my %ENV_TMP = %ENV;
  foreach my $env(  $self->environment_variable() ){
    my $val = $self->environment_variable( $env );
    if( defined $val ){ $ENV{$env} = $val }
    else{ delete( $ENV{$env} ) }
  }

  # Do the deed
  my $command = $self->command;
  $self->dispatch_qsub( $command );

  $self->debug( "BLAST COMMAND: "  .$command."\n" );
  # $self->debug( "BLAST COMMAND: ".$self->command."\n" );

  # Restore environment
  %ENV = %ENV_TMP;
  return 1;
}


#----------------------------------------------------------------------

=head2 run_blast

  Arg [1]   : None
  Function  : Fires off the blast command (SUPER::run),
              with a pre-repeatmask step
  Returntype: Boolean
  Exceptions:
  Caller    : 
  Example   :

=cut

sub run_blast{
  my $self = shift;

#  if( $self->option("repeatmask") ||
#      defined( $self->option("-RepeatMasker")  ) ){
#    uc($self->seq->alphabet) eq 'DNA' || 
#     ( $self->warn( "Can't repeatmask peptide sequences!" ) && return );
#    $self->_repeatmask;
#  }

  return $self->SUPER::run();
}

#----------------------------------------------------------------------

=head2 command_qsub

  Arg [1]   : None
  Function  : Internal method to generate the shell qsub command.
              This command calls the utils/runblast.pm wrapper script 
              rather that the blast command itself
  Returntype: String: $command
  Exceptions:
  Caller    :
  Example   :

=cut

sub command_qsub{
  my $self = shift;
#  my $program_name = "runblast.pl";
#  my $program_dir  = $SiteDefs::ENSEMBL_SERVERROOT."/utils";
  my $blastscript = $SiteDefs::ENSEMBL_BLASTSCRIPT;
  my $args         = $self->token;
  my $command      = "$blastscript $args";
  return $command;
}

#----------------------------------------------------------------------
=head2 _repeatmask

  Arg [1]   : 
  Function  : 
  Returntype: 
  Exceptions: 
  Caller    : 
  Example   : 

=cut

sub _repeatmask{
  my $self = shift;
  #TODO: expunge SpDefs
  warn ".... repeat_masker_called";
  $ENV{BLASTREPEATMASKER} = $SPECIES_DEFS->ENSEMBL_REPEATMASKER;
  return $self->SUPER::_repeatmask(@_);
}

#----------------------------------------------------------------------

=head2 command

  Arg [1]   : None
  Function  : Generate the blast command itself
  Returntype: String: $command
  Exceptions: 
  Caller    : 
  Example   : 

=cut

sub command{
  my $self = shift;

  if( ! -f $self->fastafile ){ $self->throw("Need a query sequence!") }

  my $res_file = $self->reportfile;
  if( -f $res_file ){
    $self->warn("A result already exists for $res_file" );
    unlink( $self->reportfile );
  }

  my $res_file_local = '/tmp/blast_$$.out';

  $ENV{'BLASTMAT'}    || $self->warn( "BLASTMAT variable not set" );
  $ENV{'BLASTFILTER'} || $self->warn( "BLASTFILTER variable not set" );
  $ENV{'BLASTDB'}     || $self->warn( "BLASTBD variable not set" );

  my $database = $self->database ||
    $self->throw("No database");

  my $param_str = '';
  foreach my $param( $self->option ){
    my $val = $self->option($param) || '';
    next if $param eq "repeatmask";
    next if $param eq "-RepeatMasker";
    if( $param =~ /=$/ ){ $param_str .= " $param$val" }
    elsif( $val ){ $param_str .= " $param $val" }
    else{ $param_str .= " $param" }
  }

  return join( ' ', $SPECIES_DEFS->ENSEMBL_BLAST_BIN_PATH."/".$self->program_path,
                    $SPECIES_DEFS->ENSEMBL_BLAST_DATA_PATH."/$database", '[[]]', $param_str);
}

#----------------------------------------------------------------------

=head2 dispatch_qsub

  Arg [1]   :
  Function  : Fires off the qsub command
  Returntype:
  Exceptions:
  Caller    : run method
  Example   :

=cut

sub dispatch_qsub {
   my $self = shift;
   my $command = shift || die( "Need a command to dispatch!" );
   my( $ticket ) = $self->statefile =~ m#/([^/]+$)#;
   
   ## Files on BLAST SERVER
   my $shared_tmp_dir    = $SiteDefs::ENSEMBL_SGE_SHARED_DIR;
   my $server_out_file   = "$shared_tmp_dir/$ticket.out"; 
   my $server_fail_file  = "$shared_tmp_dir/$ticket.fail";
   my $server_flag_file  = "$shared_tmp_dir/$ticket.flag";
   my $server_fasta_file = "$shared_tmp_dir/$ticket.fa";
   my $server_job_id     = "$shared_tmp_dir/$ticket.job";
   ## Files on web-blade
   my $client_out_file   = $self->reportfile;
   my $state_file        = $self->statefile;
   my @PARTS             = split /\//, $state_file;
   my $TICKET_NAME       = "$PARTS[-3]$PARTS[-2]-$PARTS[-1]";
   my $client_flag_file  = $SPECIES_DEFS->ENSEMBL_TMP_DIR_BLAST."/pending/$TICKET_NAME";
   my $client_sent_file  = $SPECIES_DEFS->ENSEMBL_TMP_DIR_BLAST."/sent/$TICKET_NAME";
   my $client_fail_file  = "$state_file.fail";
   my $client_fasta_file = $self->fastafile; 

   $command =~ s/\[\[\]\]/$server_fasta_file/;

   my $queue = $self->priority || 'offline';
   my $jobid;
   my $host = hostname();
    my $pid;
    local *QSUB;
   
   warn "#### dispatch_qsub_called";
   my $repeatmask_command = '/usr/local/bioinf/bin/RepeatMasker';

    copy($client_fasta_file, $server_fasta_file); # copy the input fasta file to the SGE shared dir
    $ENV{'SGE_ROOT'} = $SiteDefs::ENSEMBL_SGE_ROOT;
#   if( open(QSUB, qq(|qsub $QSUB_RESOURCE -N $ticket -S /bin/bash -o /dev/null -e $shared_tmp_dir/sge.e) )) {
    my $SGE_JobName = "EnsBlast_" . $ticket;
    if( open(QSUB, qq(|qsub $QSUB_RESOURCE -N $SGE_JobName -S /bin/bash -o /dev/null -e /dev/null) )) {
      if( open(FH,">$client_sent_file" ) ) {
        print FH "$state_file";
        close FH;
      }
      $self->_init_command_string();
       if( 
         ( $self->option("repeatmask") || defined( $self->option("-RepeatMasker") ) ) &&
         ( uc($self->seq->alphabet) eq 'DNA' )
       ) {
        $self->_add_command( qq( echo \$JOB_ID > $server_job_id)); # wirte SGE job id to a file
        $self->_add_command( qq( $repeatmask_command $server_fasta_file ), ## Run repeat masker
                             qq( rm $server_fasta_file.out ),              ## Remove all of the temporary files
                             qq( rm $server_fasta_file.stderr ),
                             qq( rm $server_fasta_file.cat ),
                             qq( rm $server_fasta_file.RepMask ),
                             qq( rm $server_fasta_file.RepMask.cat ),
                             qq( rm $server_fasta_file.masked.log ),
                             qq( mv $server_fasta_file.masked $server_fasta_file ) ); ## Copy back the repeat masked file!
      }
      $self->_add_command( "$command >$server_out_file 2>$server_fail_file" ); # Run the blast, sending output to local temp file
      $self->_add_command( 'status=$?' );
      $self->_add_command( "echo '$state_file' > $server_flag_file" );                        # Touch flag file so that can indicate blast has finished
      $self->_add_command( qq($SiteDefs::ENSEMBL_SGE_RCP_CMD "$server_out_file"  "$host:$client_out_file"),
                           qq($SiteDefs::ENSEMBL_SGE_RCP_CMD "$server_fail_file" "$host:$client_fail_file"),
                           qq($SiteDefs::ENSEMBL_SGE_RCP_CMD "$server_flag_file" "$host:$client_flag_file") ); # Copy all files back...
      $self->_add_command( qq(rm -f "$shared_tmp_dir"/$ticket.*) );                         # Now tidy up the temporary files
      $self->_add_command( 'exit $status' );
      print QSUB $self->_command_string();
      close QSUB;
      if ($? != 0) {
        die("qsub exited with non-zero status - job not submitted\n");
      }
    } else {
      die("Could not exec qsub : $!\n");
    }
    
   return 1;
}

sub _init_command_string {
  my $self = shift;
  $self->{'command_string'} = '';
}

sub _add_command {
  my $self = shift;
  warn join "\n",@_,"";
  $self->{'command_string'} .= join "\n", @_, '';
}

sub _command_string {
  my $self = shift;
  return $self->{'command_string'};
}
#----------------------------------------------------------------------
sub remove{
  my $self = shift;

  my( $ticket ) = $self->statefile =~ m#/([^/]+$)#;

  my $shared_tmp_dir    = $SiteDefs::ENSEMBL_SGE_SHARED_DIR;
  my $server_job_id     = "$shared_tmp_dir/$ticket.job";
 
  if( -e $server_job_id) {
 
    open(JF, "<$server_job_id");
    my @jf_content = <JF>;
    close(JF);
    my $job_id = $jf_content[0];
    chomp($job_id);
 
    my $sec = 10;
    local $SIG{ALRM} = sub{ die( "qdel timeout ($sec secs)\n" ) };

    my $out;
    eval{
	alarm( $sec );
	$out = `qdel $job_id 2>&1`;
	alarm( 0 );
    };
    if( $@ ){ die( $@ ) }
    warn ( "QSUB REMOVING $ticket: ",$out );
    $self->SUPER::remove();
  }
}

#----------------------------------------------------------------------

1;
