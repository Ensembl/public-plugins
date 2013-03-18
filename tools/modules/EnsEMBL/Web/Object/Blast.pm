package EnsEMBL::Web::Object::Blast;

### NAME: EnsEMBL::Web::Object::Blast
### Object for accessing Ensembl Blast back end 

### PLUGGABLE: Yes, using Proxy::Object 

### STATUS: Under development

### DESCRIPTION
## The aim is to create an object which can be updated to
## use a different queuing mechanism, without any need to
## change the user interface. Where possible, therefore,
## public methods should accept the same arguments and 
## return the same values

use strict;
use warnings;
no warnings "uninitialized";


use base qw(EnsEMBL::Web::Object::Tools);

use IO::Scalar;
use Bio::SeqIO;
use EnsEMBL::Web::SpeciesDefs;
use EnsEMBL::Web::ToolsConstants;
our $VERBOSE = 1;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new( @_ );
  $self->{'_analysis'}    = {};
  $self->{'_species'}     = ();
  $self->{'_seqs'}        = {};
  $self->{'_methods'}     = '';
  $self->{'_database'}    = {};
  $self->{'_input_type'}  = ''; 
  $self->{'_error'}       = {};
  $self->{'_description'} = '';
  $self->{'_config'} = {};

  return $self;
}

sub create_jobs {
  my ($self, $ticket) = @_;

  my $hive_adaptor = $self->hive_adaptor;
  my $job_adaptor = $hive_adaptor->get_AnalysisJobAdaptor;
  my $analysis_name = $ticket->job->job_type;
  my $hive_analysis = $hive_adaptor->get_AnalysisAdaptor->fetch_by_logic_name_or_url($analysis_name);    
  my @hive_jobs = ();

  my $sequences;
  foreach (keys %{$self->{'_seqs'}}){
    $sequences->{$_} = $self->{'_seqs'}->{$_}->seq;
  }

  # one Hive job per species, for now allow multiple query sequences
  foreach my $species ( @{$self->{'_species'}} ){ 
    my $dba = $self->hub->database('core', $species);
    my $dbc = $dba->dbc;

    my %input = (
      ticket        => $ticket->ticket_id,
      ticket_name   => $ticket->ticket_name,
      database      => $self->{'_database'}{$species}{'file'},
      method        => $self->{'_methods'},
      seqs          => $sequences,
      query_type    => $self->{'_input_type'}, 
      workdir       => $self->workdir,
      config        => $self->{'_config'},
      species       => $species,
      database_type => $self->{'_database'}{$species}{'type'},
      dba           => { 
        -user             => $dbc->username,
        -host             => $dbc->host,
        -port             => $dbc->port,
        -pass             => $dbc->password,
        -dbname           => $dbc->dbname,
        -driver           => $dbc->driver,
        -species          => $dba->species,
        -species_id       => $dba->species_id,
        -multispecies_db  => $dba->is_multispecies,
        -group            => $dba->group,
      },
      ticket_dbc    => {
        -user             => $self->species_defs->DATABASE_WRITE_USER,
        -pass             => $self->species_defs->DATABASE_WRITE_PASS,
        -host             => $self->species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
        -port             => $self->species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
        -dbname           => $self->species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'}
      }
    );
    
    $input{mask} = 1 if $self->{'_repeat_mask'};
 
    # Pass job to ensembl-hive 
    my $job_id = $job_adaptor->CreateNewJob(
      -input_id => \%input,
      -analysis => $hive_analysis,
    );

    my $job_division = {
      species => $species,
      type    => $self->{'_database'}{$species}{'type'},
    };

    my $serialised_division = $self->serialise($job_division);  
    push (@hive_jobs, {ticket_id => $ticket->ticket_id, sub_job_id => $job_id, job_division => $$serialised_division }) if $job_id != 0;
  }


  $ticket->sub_job(\@hive_jobs);
  $ticket->save(cascade => 1);
  $self->check_submission_status($ticket);

  return;
}

##----------------------------------------------------------- BLAST set up
sub species_defs  { return new EnsEMBL::Web::SpeciesDefs; }

sub get_blast_form_params {
  my $self    = shift;
  my $species = shift || $self->species;
  my $query   = shift || 'dna';
  my $db_type = shift || 'dna';
  my $db_name = shift || '';
  my $me      = shift || '';

  my ( @methods, @databases, $default_me, $default_db, $valid_method, $valid_db );
  my $species_defs = $self->species_defs;

  if ( $query eq 'dna'){ $default_me = $db_type eq 'dna' ? 'BLASTN'   : 'BLASTX'; }
  else { $default_me = $db_type eq 'dna' ? 'TBLASTN' : 'BLASTP'; }

  $default_db = $db_type eq 'dna' ? 'LATESTGP' : 'PEP_ALL';
  unless ($db_name =~/^\w+/ ){ $db_name = $default_db; }

  my $method_conf = $species_defs->multi_val('ENSEMBL_BLAST_METHODS');
  foreach my $method (sort keys %$method_conf ){
    next if $method eq 'BLAT'; # disable until have working
    my $method_query_type = $method_conf->{$method}->[1];
    my $method_db_type = $method_conf->{$method}->[2];
    $method_query_type  =~ s/peptide/protein/;
    $method_db_type =~ s/peptide/protein/;
    if ( $query eq $method_query_type && $db_type eq $method_db_type){
      next if $species eq 'Dasypus_novemcinctus' && $method eq 'BLAT';
      next if $db_name ne 'LATESTGP' && $method eq 'BLAT';
      $valid_method = 1 if $me eq $method;
      push @methods, $method;
    }
  }



  if ( $me && $valid_method){ $default_me = $me;}
  else  { $me = $default_me; }


  my $conf = $species_defs->get_config($species , $me ."_DATASOURCES");
  foreach my $db (sort keys %$conf ){
    next if $db =~/^DATASOURCE/; 
    my $label = $conf->{$db}->{'label'};
    push @databases, { value => $db, name => $label };
    $valid_db = 1 if $db eq $db_name;
  }

  if ( $db_name && $valid_db){ $default_db = $db_name; }

  return (\@databases, \@methods, $default_db, $default_me);
}


sub blast_methods {
  my $self = shift;
  my $method_conf = $self->species_defs->multi_val('ENSEMBL_BLAST_METHODS');
  if( ref( $method_conf ) ne 'HASH' or ! scalar( %$method_conf ) ){
    warn( "ENSEMBL_BLAST_METHODS config unavailable" );
    return;
  }

  return $method_conf;
}

sub blast_datasources_by_species {
  my ($self, $species) = @_;
  return unless $species;

  my $datasources = {};

  foreach my $sp (@$species){
    my $methods = $self->blast_methods;

    foreach my $me (keys %$methods){
      my $conf = $self->species_defs->get_config($sp, "${me}_DATASOURCES");
      # Check that there's something in the conf
      if( ref( $conf ) ne 'HASH' or ! scalar( keys %$conf ) ){ next; }

      my $dty = $conf->{DATASOURCE_TYPE};
      foreach my $db ( sort keys %$conf) {
        if( $db =~ /^DATASOURCE/ ){ next }
        my $qty = $db =~/PEP/ ? 'protein' : 'dna';
        my $lb = $conf->{$db};
        $datasources->{$qty} ||= {};
        $datasources->{$qty}->{$sp} ||= {};
        $datasources->{$qty}->{$sp}->{$db} ||= {};
      }
    }
  }

  return $datasources;
}



##----------------------------------------------------------- Form input validation
sub validate_form_input {
  my $self = shift;
  
  $self->process_species;
  $self->process_input_sequence;
  $self->process_input_type;  
  $self->process_method;
  $self->process_database;
  $self->process_description; 
  $self->process_config_params;

  return keys %{$self->{'_error'}} ? $self->{'_error'} : undef;
}

sub process_species {
  my $self = shift;
  my @spp;
  my $species = $self->param('species'); # at the moment form allows selection of single species - this will change
  if ($self->species_defs->valid_species($species) ){
    push @spp, $species;
  } else {
    $self->{'_error'}{'species'} = 'Please enter a valid species'; 
    return;    
  }

  $self->{'_species'} = \@spp;  
  return;
}

sub process_input_sequence {
  my $self = shift; 
  my $i = 0; 
  my $length = 0;
  
  if ( my $file = $self->param('file') ){ 
    my $file_contents;
    { 
      local $/ = undef;
      $file_contents = <$file>;
    } 
    close $file;

    my $fh = IO::String->new($file_contents);
    my $seq_io = Bio::SeqIO->new(-fh=>$fh );  
    while( my $seq = $seq_io->next_seq ){ 
      $length += $seq->length;
      $i++; 
      $self->add_seq($seq, $i, $length, 'file'); 
      last if exists $self->{'_error'}{'file'};
    }
    $self->hub->delete_param('file');
    $self->{'data'}{'_input'}{'.tmpfiles'} = {};
  }
  elsif ( my $seq = $self->param('query_sequence') and $self->param('query_sequence') !~ /^\*\*\*/o ){
    $seq =~ s/^\s+//;
    if( $seq !~ /^>/ ){ $seq = ">unnamed\n".$seq }
    my $fh = IO::Scalar->new(\$seq);
    my $seq_io = Bio::SeqIO->new(-fh=>$fh );
    while( my $bioseq = $seq_io->next_seq){
      $length += $bioseq->length;
      $i++; 
      $self->add_seq($bioseq, $i, $length, 'query_sequence'); 
      last if exists $self->{'_error'}{'query_sequence'};
    }    
  }
  else {
    $self->{'_error'}{'file'} = 'No query sequences have been entered';
    return;
  }  
}

sub process_input_type {
  my $self = shift;
  my $input_type =  $self->param('query'); 
  # check that input type specified by form matches sequences provided 
  my @seqs = values %{$self->{'_seqs'}};
  foreach my $seq (@seqs){
    if ($input_type ne $seq->alphabet){ 
      $self->{'_error'}{'query'} = "The query sequence " . $seq->id ." does not match the selected query sequence type";
      return '';
    }
  }

  $self->{'_input_type'} = $input_type;    
  
}

sub process_method {
  my $self = shift;

  my $method = $self->param('blastmethod'); 
  if ( $method eq 'Blat'){
    $self->{'_analysis'} = $method;
    $self->{'_methods'} = $method;
    return;
  } else {
    $self->{'_analysis'} = 'Blast';
  }

  my %tmp_methods = %{$self->species_defs->multi_val('ENSEMBL_BLAST_METHODS_' . $self->param('blast_type')) || {}};
  my %methods;

  while (my ($k, $v) = each (%tmp_methods)) {
    next unless ref($v) eq 'ARRAY';
    $methods{$k} = $v->[3];
  }

  my $me = $methods{$method};
  $self->{'_methods'} = $me;

  return;
}

sub process_database {
  my $self = shift;
  my $db_key = $self->param('db_name'); 
  my $sp = $self->param('species'); # Needs expanding to allow multiple species to be selected 
  my $me_key = $self->param('blastmethod')."_DATASOURCES";
  my $datasources = $self->species_defs->get_config( $sp, $me_key ) || warn "Nothing in config $sp: $me_key";
  ref( $datasources ) eq 'HASH' || warn "Nothing in config $sp: $me_key";
  my $db_str = $datasources->{$db_key}|| warn"Nothing in config $sp: $me_key: $db_key";
  $db_str->{'type'} = $self->param('db_name');

  my %db = (
    $sp => $db_str,
  );
   
  $self->{'_database'} = \%db;
}

sub process_description {
  my $self = shift;

  my $desc = $self->param('description') || undef;

  if (defined $desc){    
    $self->{'_description'} = $desc;
    return;
  }

  my $search_type = $self->param('blastmethod'); 
  my $species_name = $self->hub->species_defs->get_config($self->param('species'),'SPECIES_COMMON_NAME');
  my $db_type = $self->param('db_name');
  my ($dbs, $methods, $default_db, $default_me) = $self->get_blast_form_params; 
  my @db_name = map  { $_->{'name'} } grep { $_->{'value'} eq $db_type } @{$dbs};
 
  my $ticket_summary = sprintf ( '%s search against %s %s database.  ',
                              uc($search_type),
                              $species_name,
                              lc ($db_name[0])
  );

  $self->{'_description'} = $ticket_summary;
}

sub process_config_params {
  my $self = shift;
  my $options; 

  my %config_options =  EnsEMBL::Web::ToolsConstants::BLAST_CONFIGURATION_OPTIONS;
  
  my $options_and_defaults = $config_options{'options_and_defaults'};

  foreach my $category ( keys %$options_and_defaults ){
    foreach my $option ( @{$options_and_defaults->{$category}}){
      my ($opt, $methods) = @$option;
      if ($methods->{$self->{'_methods'}} || $methods->{'all'}){
        my $value = $self->param($opt);
        my $type = $config_options{$category}{$opt}{'type'};

        if ($value eq 'yes' && $opt eq 'repeat_mask'){ 
          $self->{'_repeat_mask'} = '1';
          next;  
        }

        #check have a valid value
        if ( $type eq 'DropDown') {
          if (grep  {$_->{value} eq $value } @{$config_options{$category}{$opt}{'values'}}) {
            $options->{$opt} = $value;
          } else {
            $self->{'_error'}{$opt} = "The value specified is not valid";
            return;
          }
        } elsif($type eq 'CheckBox'){
          if ($opt eq 'ungapped'){
            $options->{$opt} = '' unless $value eq 'no';
          } else {           
          $options->{$opt} = $value ?  $value : 'no';          
          } 
        } elsif( $type eq 'String') { 
          next if $value eq 'START-END';
          my $temp = $value;
          my ($start, $end ) = split(/-/, $temp);
          my @seqs = values %{$self->{'_seqs'}};
          my $seq_count = scalar @seqs;  
          my $query_seq = shift @seqs;
          my $query_length = $query_seq->length;
          
          # Check values are in correct format
          if ($value !~/^\d+-\d+$/ ) { 
            $self->{'_error'}{'config_' .$opt} =  "Please specify location on the query sequence in the format 'START-END'";
            return;
          } elsif ( $seq_count != 1 ){ 
            $self->{'_error'}{'config_'.$opt} =  "This option is only valid for a single query sequence";
            return;
          } elsif ($start > $end ){
            $self->{'_error'}{'config_'. $opt} =  "Query start is higher than query end, please check the values you have entered";
            return;
          } elsif($start < 0 || $end > $query_length){
            $self->{'_error'}{'config_'. $opt} =  "The coordinates you have entered are not valid for your query sequence";
            return;
          }
        }  
      }
    }    
  }

  $self->{'_config'} = $options;  
}


sub add_seq {
  my ($self, $seq, $seq_count, $seq_length, $error_type)  = @_;
  my $max_queries = 10; 
  my $method = $self->param('method');
  my %max_lengths = (
          DEFAULT => 200000 );
  my $max_length = $max_lengths{$method} || $max_lengths{DEFAULT};
  my $max_number = 30;

  unless( ref($seq) && $seq->isa("Bio::Seq") && $seq->validate_seq){
    return $self->{'_error'}{$error_type} = "No queries submitted: ".
      "Query sequence is not of a recognised format";
  }

  # Check not exceeded number of input sequences or query length:
  if ($seq_count > $max_queries){ 
    return $self->{'_error'}{$error_type} =  "No queries submitted: ".
      "The maximum number of query sequences ($max_number) has been exceeded.";
  } elsif ($seq_length > $max_length){
    return $self->{'_error'}{$error_type} = "No queries submitted: ".
      "The maximum length for a single query sequence ".
      "($max_length bp for $method) ".
      "has been exceeded";
  }     

  # Get a unique ID
  my $id = $seq->display_id() || 'Unknown';  
  my $id_new = $id; 
  my $i = 0; 
  if ( $self->{'_seqs'}->{$id} ){
    $i++; 
    $id_new = $id.'_copy'.$i; 
  }
  $id = $id_new; 
  $seq->display_id( $id ); 
  $self->{'_seqs'}->{$id} = $seq;

  return $id;

}

sub workdir {
  my $self = shift;
  return  $self->species_defs->ENSEMBL_TMP_DIR_BLAST;
}

1;
