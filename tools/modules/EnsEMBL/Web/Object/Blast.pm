package EnsEMBL::Web::Object::Blast;

## The aim is to create an object which can be updated to
## use a different queuing mechanism, without any need to
## change the user interface. Where possible, therefore,
## public methods should accept the same arguments and
## return the same values

use strict;
use warnings;

use base qw(EnsEMBL::Web::Object::Tools);

use FileHandle;
use Bio::SeqIO;
use Bio::EnsEMBL::Registry;
use EnsEMBL::Web::SpeciesDefs;
use EnsEMBL::Web::BlastConstants;
use EnsEMBL::Web::ExtIndex;

our $VERBOSE = 1;

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( @_ );

  $self->{'_input'}       = {};
  $self->{'_error'}       = {};
  $self->{'_job_inputs'}  = [];



  $self->{'_analysis'}    = {};
  $self->{'_species'}     = ();
  $self->{'_seqs'}        = {};
  $self->{'_methods'}     = '';
  $self->{'_database'}    = {};
  $self->{'_input_type'}  = '';
  $self->{'_description'} = '';
  $self->{'_config'} = {};

  return $self;
}

sub ticket_prefix {
  ## Abstract method implementation
  return 'BLA_';
}

sub process_job_for_hive_submission {
  ## Abstract method implementation
  my ($self, $job) = @_;

  my $job_data = $job->job_data->raw;

  if ($job_data->{'sequence'}{'is_invalid'}) {
    $job->job_message([{'display_message' => $job_data->{'sequence'}{'is_invalid'}}]);
    return;
  }

  my $hub   = $self->hub;
  my $dba   = $hub->database('core', $job_data->{'species'});
  my $dbc   = $dba->dbc;
  my $sd    = $hub->species_defs;

  $job_data->{'dba'}  = {
    -user               => $dbc->username,
    -host               => $dbc->host,
    -port               => $dbc->port,
    -pass               => $dbc->password,
    -dbname             => $dbc->dbname,
    -driver             => $dbc->driver,
    -species            => $dba->species,
    -species_id         => $dba->species_id,
    -multispecies_db    => $dba->is_multispecies,
    -group              => $dba->group
  };

  my @search_type = $self->parse_search_type(delete $job_data->{'search_type'});

  $job_data->{'blast_type'} = $search_type[0];
  $job_data->{'program'}    = lc $search_type[1];

  return $job_data;
}

sub get_blast_form_params {
  ## Gets the field params for the blast input form
  ## @param Hashref with keys:
  ##  - species     arrayref of selected species
  ##  - query_type  selected query type
  ##  - db_type     selected db type to search the query against
  ##  - search_type selected method eg. NCBIBLAST|BLASTP, BLAT|BLAT etc
  ##  - source      selected db name eg. LATESTGP, NCRNA, PEP_ALL etc
  my ($self, $params) = @_;

  my $hub                     = $self->hub;
  $params                   ||= {};
  $params->{'species'}      ||= [];
  $params->{'query_type'}   ||= '';
  $params->{'db_type'}      ||= '';
  $params->{'search_type'}  ||= '';
  $params->{'source'}       ||= '';

  my $sd                      = $self->species_defs;
  my @all_species             = $sd->valid_species;
  my %requested_species       = map {$_ => 1} @{$params->{'species'} || []};
  my @species                 = grep $requested_species{$_}, @all_species;
  if (!@species) {
    @species                  = ($hub->species);
    @species                  = ($hub->get_favourite_species->[0]) if $species[0] =~ /multi|common/i;
  }

  my %species_confs           = map { $_ => $sd->get_config($_, 'ENSEMBL_BLAST_CONFIGS') } @species;
  my $blast_types             = $sd->multi_val('ENSEMBL_BLAST_TYPES');
  my $query_types             = $sd->multi_val('ENSEMBL_BLAST_QUERY_TYPES');
  my $db_types                = $sd->multi_val('ENSEMBL_BLAST_DB_TYPES');
  my $blast_methods           = $sd->multi_val('ENSEMBL_BLAST_CONFIGS');
  my $sources                 = $sd->multi_val('ENSEMBL_BLAST_DATASOURCES');
  my $search_types            = [ map { $_->{'search_type'} } @$blast_methods ]; # NCBIBLAST|BLASTN, NCBIBLAST|BLASTP, BLAT|BLAT etc

  # Fields to return
  my $fields                  = {};

  # Options to be selected on the form by default
  my $selected                = {};

  # A multidimensional map to link valid search types for query type, db type, search type and sources
  my $options_map             = [];

  foreach my $blast_method (@$blast_methods) {
    my %details = map { $_ => $blast_method->{$_} } qw(query_type db_type search_type);
    foreach my $source (@{$blast_method->{'sources'}}) {
      push @$options_map, { %details, 'source' => $source, 'species' => [] };
    }
  }

  # Filter the parameters to the ones supported by the selected species - %species_confs = species => {query_type => {db_type => {search_type => {source => ?}}}}
  while (my ($species, $species_conf) = each %species_confs) {

    # add an entry for this species for each combination of options that it can accept
    foreach my $query_type (keys %$species_conf) {
      foreach my $db_type (keys %{$species_conf->{$query_type}}) {
        foreach my $search_type (keys %{$species_conf->{$query_type}{$db_type}}) {
          foreach my $source (keys %{$species_conf->{$query_type}{$db_type}{$search_type}}) {
            for (grep {$_->{'query_type'} eq $query_type && $_->{'db_type'} eq $db_type && $_->{'search_type'} eq $search_type && $_->{'source'} eq $source} @$options_map) {
              push @{$_->{'species'}}, $species;
            }
          }
        }
      }
    }
  }

  # Return fields
  $fields->{'species'}        = [ map { 'value' => $_, 'caption' => $sd->species_label($_, 1) }, @species                         ];
  $fields->{'query_type'}     = [ map { 'value' => $_, 'caption' => $query_types->{$_}        }, keys %$query_types               ];
  $fields->{'db_type'}        = [ map { 'value' => $_, 'caption' => $db_types->{$_}           }, keys %$db_types                  ];
  $fields->{'source'}         = [ map { 'value' => $_, 'caption' => $sources->{$_}            }, sort {$a cmp $b} keys %$sources  ];
  $fields->{'search_type'}    = [];
  foreach my $search_type (@$search_types) {
    my ($blast_type, $search_method) = $self->parse_search_type($search_type);
    push @{$fields->{'search_type'}}, { 'value' => $search_type, 'caption' => $search_method, 'group' => $blast_types->{$blast_type} };
  }

  # Now make the first valid option from the option list 'checked'
  # If already selected, validate the selected one, and set 'checked' key to true
  SELECTION:
  foreach my $query_type ($params->{'query_type'} || (),  map $_->{'value'}, @{$fields->{'query_type'}}) {
    foreach my $db_type ($params->{'db_type'} || (),  map $_->{'value'}, @{$fields->{'db_type'}}) {
      foreach my $search_type ($params->{'search_type'} || (),  map $_->{'value'}, @{$fields->{'search_type'}}) {
        foreach my $source ($params->{'source'} || (),  map $_->{'value'}, @{$fields->{'source'}}) {
          for (
            sort { @{$a->{'species'}} <=> @{$b->{'species'}} }
            grep {$_->{'query_type'} eq $query_type && $_->{'db_type'} eq $db_type && $_->{'search_type'} eq $search_type && $_->{'source'} eq $source && @{$_->{'species'}}}
            @$options_map
          ) {
            $selected = {
              'species'         => $_->{'species'},
              'query_type'      => $query_type,
              'db_type'         => $db_type,
              'search_type'     => $search_type,
              'source'          => $source
            };
            last SELECTION;
          }
        }
      }
    }
  }

  return {
    'species'       => [ map { 'value' => $_, 'caption' => $sd->species_label($_, 1) }, @all_species ],
    'fields'        => $fields,
    'selected'      => $selected,
    'combinations'  => $self->jsonify($options_map)
  };
}

sub form_inputs_to_jobs_data {
  ## Abstract method implementation
  ## Validates the inputs, then create set of parameters for each job, ready to be submitted
  ## @return undefined if any of the parameters (other than sequences/species) are invalid (no specific message is returned since all validations were done at the frontend first - if input is still invalid, someone's just messing around)
  my $self      = shift;
  my $hub       = $self->hub;
  my $sd        = $hub->species_defs;
  my $params    = {};

  # Validate Species
  my @species = $sd->valid_species($hub->param('species'));
  return unless @species;

  # Validate Query Type, DB Type, Source Type and Search Type
  for (qw(query_type db_type source search_type)) {
    my $param_value = $params->{$_} = $hub->param($_);
    return unless $param_value && $self->get_param_value_caption($_, $param_value); #get_param_value_caption returns undef if value is invalid
  }

  # process the extra configurations
  $params->{'configs'} = $self->process_extra_configs($params->{'search_type'});
  return unless $params->{'configs'};

  # Process input sequences
  my $input_seqs  = join "\n\n", $self->param('sequence');
  my $file_handle = FileHandle->new(\$input_seqs, 'r');
  my $seq_io      = Bio::SeqIO->new('-fh' => $file_handle, '-alphabet' => $params->{'query_type'} eq 'peptide' ? 'protein' : 'dna', '-format' => 'fasta');
  my $seq_objects = [];

  while (my $seq_object = $seq_io->next_seq) {
    my $is_invalid  = $seq_object->validate_seq ? 0 : 1;
    my $seq_string  = $seq_object->seq;
    $is_invalid     = sprintf 'Sequence contains more than %s characters', MAX_SEQUENCE_LENGTH if !$is_invalid && length $seq_string > MAX_SEQUENCE_LENGTH;
    push @$seq_objects, {
      'display_id'  => $seq_object->display_id,
      'seq'         => $seq_string,
      'is_invalid'  => $is_invalid
    };
  }
  $file_handle->close;

  # Create parameter sets for individual jobs to be submitted (submit one job per sequence per species)
  my $jobs    = [];
  my $desc    = $self->param('description');
  my $prog    = $self->parse_search_type($params->{'search_type'}, 'search_method');
  for my $species (@species) {
    my $i = 0;
    for my $seq_object (@$seq_objects) {
      push @$jobs, {
        'job_desc'    => sprintf('%s%s', $desc || sprintf('%s search against %s %s database.', $prog, $sd->get_config($species, 'SPECIES_COMMON_NAME'), $params->{'db_type'}), @$seq_objects > 1 ? sprintf(' (%d)', ++$i) : ''),
        'species'     => $species,
        'sequence'    => $seq_object,
        'source_file' => $sd->get_config($species, 'ENSEMBL_BLAST_CONFIGS')->{$params->{'query_type'}}{$params->{'db_type'}}{$params->{'search_type'}}{$params->{'source'}},
        %$params
      };
    }
  }

  return $jobs;
}

sub process_extra_configs {
  ## Gets all the extra configs from CGI depending upon the selected search type
  ## @param Search type string
  ## @return Hashref of config params, or undef in case of validation error
  my ($self, $search_type_value) = @_;

  my $config_fields   = CONFIGURATION_FIELDS;
  my $config_defaults = CONFIGURATION_DEFAULTS;
  my $config_values   = {};

  while (my ($config_type, $config_field_group) = splice @$config_fields, 0, 2) {

    while (my ($element_name, $element_params) = splice @$config_field_group, 0, 2) {

      for ($search_type_value, 'all') {
        if (exists $config_defaults->{$_}{$element_name}) {

          my $element_value = $self->param("${search_type_value}__${element_name}") // '';

          return unless grep {$_ eq $element_value} map($_->{'value'}, @{$element_params->{'values'}}), $element_params->{'type'} eq 'checklist' ? '' : (); # checklist is also allowed to have null value

          if (($element_params->{'commandline_type'} || '') eq 'flag') {
            $config_values->{$element_name} = '' if $element_value;
          } else {
            $config_values->{$element_name} = exists $element_params->{'commandline_values'} ? $element_params->{'commandline_values'}{$element_value} : $element_value;
          }

          last;
        }
      }
    }
  }

  return $config_values;
}

sub get_param_value_caption {
  ## Gets the display caption for a value for a given param type
  ## @param Param type string (query_type, db_type, source or search_type)
  ## @param Value
  ## @return String caption, if param value is valid, undef otherwise
  my ($self, $param_name, $param_value) = @_;

  my $hub = $self->hub;
  my $sd  = $hub->species_defs;

  if ($param_name eq 'search_type') {
    my $blast_types = $sd->multi_val('ENSEMBL_BLAST_TYPES');
    for (@{$sd->multi_val('ENSEMBL_BLAST_CONFIGS')}) {
      if ($param_value eq $_->{'search_type'}) {
        my ($blast_type, $search_method) = $self->parse_search_type($param_value);
        return sprintf '%s (%s)', $search_method, $blast_types->{$blast_type};
      }
    }
  } else {

    my %param_type_map = qw(query_type ENSEMBL_BLAST_QUERY_TYPES db_type ENSEMBL_BLAST_DB_TYPES source ENSEMBL_BLAST_DATASOURCES);
    if (my $sd_key = $param_type_map{$param_name}) {
      my $param_details = $sd->multi_val($sd_key);
      return $param_details->{$param_value} if exists $param_details->{$param_value};
    }
  }
}

sub parse_search_type {
  ## Parses the search type value to get blast type and actual search method name
  ## @param Search type string
  ## @param (optional) required key (blast_type or search_method)
  ## @return List of blast_type and search_method values if required key not specified, individual key value otherwise
  my ($self, $search_type, $required_key) = @_;
  my @search_type = split /_/, $search_type;
  if ($required_key) {
    return $search_type[0] if $required_key eq 'blast_type';
    return $search_type[1] if $required_key eq 'search_method';
  }
  return @search_type
}

sub get_target_object {
  ## Gets the target genomic object according to the target Id of the blast result's hit
  ## @param Blast result hit
  ## @return PredictionTranscript/Transcript/Translation object
  my ($self, $hit)  = @_;
  my $target_id     = $hit->{'tid'};
  my $species       = $hit->{'species'};
  my $source        = $hit->{'source'};
  my $feature_type  = $source =~ /abinitio/i ? 'PredictionTranscript' : $source =~ /cdna/i ? 'Transcript' : 'Translation';
  my $adaptor       = $self->hub->get_adaptor("get_${feature_type}Adaptor", 'core', $species);
  
  return $adaptor->fetch_by_stable_id($target_id);
}




##/*********************************************/


sub blast_methods {
  my $self = shift;
  my $method_conf = $self->species_defs->multi_val('ENSEMBL_BLAST_METHODS');
  if( ref( $method_conf ) ne 'HASH' or ! scalar( %$method_conf ) ){
    warn( "ENSEMBL_BLAST_METHODS config unavailable" );
    return;
  }

  return $method_conf;
}

sub process_input_sequence { ## DONT DELETE THIS YET! THIS CONTAINS THE ACCESSION ID RETRIEVAL CODE
  my $self    = shift;
  my $i       = 0;
  my $length  = 0;

  if ( my $file = $self->param('file') ) {
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
  elsif (my $id = $self->param('retrieve_accession')){
    my $seq;

    if ($id =~/^ENS[GTP]\d{11}?/ || $id =~/^ENS\w\w\w[GTP]\d{11}?/){ # Have Ensembl sequence
      my ($species, $object_type, $db_type) = Bio::EnsEMBL::Registry->get_species_and_object_type($id);
      my $adaptor = $self->hub->get_adaptor('get_' . $object_type .'Adaptor', $db_type, $species);
      my $seq_object = $adaptor->fetch_by_stable_id($id);

      if ($object_type eq 'Gene' || $object_type eq 'Transcript'){
        $seq = '>'.$id."\n".$seq_object->feature_Slice->seq;
      } elsif ($object_type eq 'Translation'){
        $seq = '>'.$id."\n".$seq_object->seq;
      }

      if(!$seq){
        $self->{'_error'}{'retrieve_accession'} = 'Could not retrieve sequence' . $self->param('retrieve_accession');
      }

    } else { # try and fetch via pfetch
      my $indexer = EnsEMBL::Web::ExtIndex->new( $self->species_defs );
      $seq = join ("", @{$indexer->get_seq_by_id({ DB =>"PUBLIC",
                                                     ID => $id})} );
      if( ! $seq or $seq =~ /^no match/ ){
      $seq = join( "", @{$indexer->get_seq_by_acc({DB=>"PUBLIC",
                                                   ACC=>$id})} );
        if( ! $seq or $seq =~ /^no match/ ){
          $self->{'_error'}{'retrieve_accession'} = 'Could not retrieve sequence' . $self->param('retrieve_accession');
        }
      }
    }

    if ($seq =~/^\w+|^\>/){
      my $fh = IO::Scalar->new(\$seq);
      my $seq_io = Bio::SeqIO->new(-fh=>$fh );
      while( my $bioseq = $seq_io->next_seq){
        $bioseq->display_id($id);
        $length += $bioseq->length;
        $i++;
        $self->add_seq($bioseq, $i, $length, 'query_sequence');
        last if exists $self->{'_error'}{'query_sequence'};
      }
    }
  }
  else {
    $self->{'_error'}{'file'} = 'No query sequences have been entered';
    return;
  }
}


sub process_config_params {
  my $self = shift;
  my $options;

  my %config_options =  CONFIGURATION_FIELDS;

  my $options_and_defaults = $config_options{'options_and_defaults'};

  foreach my $category ( keys %$options_and_defaults ){
    foreach my $option ( @{$options_and_defaults->{$category}}){
      my ($opt, $methods) = @$option;
      if ($methods->{$self->{'_methods'}} || $methods->{'all'}){
        my $value = $self->param($opt);
        my $type = $config_options{$category}{$opt}{'type'};

        if ($value eq 'yes' && $opt eq 'repeat_mask') {
          $self->{'_repeat_mask'} = '1';
          next;
        }

        #check have a valid value
        if ( $type eq 'dropdown') {
          if (grep  {$_->{value} eq $value } @{$config_options{$category}{$opt}{'values'}}) {
            $options->{$opt} = $value;
          } else {
            $self->{'_error'}{$opt} = "The value specified is not valid";
            return;
          }
        } elsif($type eq 'checkbox'){
          if ($opt eq 'ungapped'){
            $options->{$opt} = '' unless $value eq 'no';
          } else {
          $options->{$opt} = $value ?  $value : 'no';
          }
        } elsif( $type eq 'string') {
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
  my $method = $self->param('blastmethod');
  my %max_lengths = (
          DEFAULT => 200000 );
  my $max_length = $max_lengths{$method} || $max_lengths{DEFAULT};
  my $max_number = 30;

  unless( ref($seq) && $seq->isa("Bio::Seq") && $seq->validate_seq) {
    return $self->{'_error'}{$error_type} = "No queries submitted: ".
      "Query sequence is not of a recognised format";
  }

  # Check not exceeded number of input sequences or query length:
  if ($seq_count > $max_queries) {
    return $self->{'_error'}{$error_type} =  "No queries submitted: ".
      "The maximum number of query sequences ($max_number) has been exceeded.";
  } elsif ($seq_length > $max_length) {
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










#----
## ------------------------------------------------------------------------






# sub long_caption {
#   my $self = shift;
#   return 'Tools' if $self->action ne 'BlastResults';
# 
#   my $caption =  sprintf ('<h1>Results for %s: <span class="small"><a href ="%s">[Change ticket]</a></span></h1>',
#     $self->hub->param('tk'),
#     $self->hub->url({ action => 'Summary', tk => undef})
#   );
# }

#sub session_id    { return $_[0]->hub->session->session_id || undef;              }
#sub user_id       { return $_[0]->hub->user ? $_[0]->hub->user->user_id : undef;  }
#sub species_defs  { return $_[0]->hub->species_defs;                              }
#sub ticket        { return $_[0]->Obj->{'_ticket'} || undef;                      }

# sub create_ticket {
#   ## Creates a ticket by adding an entry in the ticket db
#   my $self        = shift;
#   my $hub         = $self->hub;
#   my $now         = $self->get_time_now;
#   my $user        = $hub->user;
#
#   # First create and save ticket
#   my $ticket = $self->rose_manager(qw(Tools Ticket))->create_empty_object({
#     'owner_id'    => $user ? $user->user_id : $hub->session->session_id,
#     'owner_type'  => $user ? 'user' : 'session',
#     'job_type_id' => $self->rose_manager(qw(Tools JobType))->get_job_type_id_by_name($self->{'_analysis'}),
#     'ticket_name' => $self->get_unique_ticket_name,
#     'ticket_desc' => $self->{'_description'},
#     'created_at'  => $now,
#     'modified_at' => $now,
#     'site_type'   => $self->species_defs->ENSEMBL_SITETYPE
#   });
#
#   # Then create analysis object - this contains params needed to run job
#   # create serialised and gzipped version of the analysis object to store in ticket DB.
#   my $serialised_analysis = $self->serialise;
#   $ticket->analysis(object => $$serialised_analysis);
#
#   # Finally save objects
#   $ticket->save(cascade => 1);
#
#   return $ticket;
# }

# sub submit_job {
#   my ($self, $ticket)  = @_;
#
#   my $analysis_adaptor  = $self->rose_manager(qw(Tools Analysis));
#   my $serialised_object = $analysis_adaptor->retrieve_analysis_object($ticket->ticket_id);
#   my $analysis_object = $self->deserialise($serialised_object);
#   $analysis_object->create_jobs($ticket);
#
#   return;
# }

sub display_status {
  my ($self, $job_status) = @_;

  my %status_lookup = (
    'SEMAPHORED'   => 'Pending',
    'READY'        => 'Pending',
    'BLOCKED'      => 'Pending',
    'CLAIMED'      => 'Pending',
    'COMPILATION'  => 'Pending',
    'PRE_CLEANUP'  => 'Pending',
    'FETCH_INPUT'  => 'Pending',
    'RUN'          => 'Running',
    'WRITE_OUTPUT' => 'Parsing',
    'POST_CLEANUP' => 'Parsing',
    'DONE'         => 'Completed',
    'FAILED'       => 'Failed',
    'PASSED_ON'    => 'Failed',
  );
  return $status_lookup{$job_status};
}

sub check_submission_status {
  my ($self, $ticket) = @_;
  return $ticket->status unless ref $ticket->sub_job;

  # Set ticket status to be that of the sub job that has progressed the least
  my %status_priority = (
    'Queued'    => 0,
    'Pending'   => 1,
    'Running'   => 2,
    'Parsing'   => 3,
    'Completed' => 4,
    'Failed'    => 5,
    'Deleted'   => 6,
  );

  my $status;
  foreach my $job (@{$ticket->sub_job}){
    my $display_status = $self->get_hive_job_status($job->sub_job_id);
    $status = $status_priority{$display_status} << $status_priority{$status} ? $display_status : $status
    ;
  }

  # update status in ticket db
  my $now = $self->get_time_now;
  $ticket->status($status);
  $ticket->modified_at($now);
  if ($status eq 'Completed' || $status eq 'Failed') {
    # If ticket is complete set all modified/created dates for data belonging to this ticket to be
    # the same - that way all data will be in equivalent partitions and will be removed at same time
    $ticket->analysis->modified_at($now);
    foreach (@{$ticket->sub_job}){ $_->modified_at($now); }
    foreach (@{$ticket->result}){ $_->modified_at($now); }
  }
  $ticket->save(cascade => 1);

  return $status;
}


sub get_hive_job_status { ## TODO remove
  my ($self, $hive_job_id) = @_;
  my $job_adaptor = $self->hive_adaptor->get_AnalysisJobAdaptor;
  my $job_status = $job_adaptor->fetch_by_dbID($hive_job_id)->status;

  return  $self->display_status($job_status);
}

sub get_hive_job_message {
  my ($self, $hive_job_id) = @_;
  my $adaptor = $self->hive_adaptor->get_NakedTableAdaptor();
  $adaptor->table_name('job_message');
  my $job_message_record = $adaptor->fetch_by_job_id($hive_job_id);
  my ($job_message, $line) = $job_message_record->{'msg'} =~/(.*)at(.*)$/;

  return $job_message;
}

sub format_date { ## TODO ??? move to root?
  my ($self, $datetime) = @_;
  return unless $datetime;

  my @date = split(/-|T|:/, $datetime);
  $datetime = sprintf('%s/%s/%s, %s:%s',
    $date[2],
    $date[1],
    $date[0],
    $date[3],
    $date[4]
  );
  return $datetime;
}

sub delete_ticket {
  my ($self, $ticket_id) = @_;
  my $ticket = $self->rose_manager(qw(Tools Ticket))->fetch_ticket_by_name($ticket_id);
  return unless $ticket;

  # First clean up any results files
  my $work_dir =  $self->species_defs->ENSEMBL_TMP_DIR_BLAST;
  my $file_directory = $work_dir ."/" . substr($ticket->ticket_name, 0, 6) ."/" . substr($ticket->ticket_name, 6);
  my $parent_directory = $work_dir ."/" . substr($ticket->ticket_name, 0, 6);

  if (-d $file_directory){
    foreach my $sub_job (@{$ticket->sub_job}){
      my $filename = $file_directory .'/'. $ticket->ticket_id . $sub_job->sub_job_id;
      my @exts = ('seq.fa', 'seq.fa.masked', 'seq.fa.tab', 'seq.fa.out', 'seq.fa.raw');
      foreach (@exts){
        my $file = $filename .'.'. $_;
        if ( -s $file ){
          unlink($file);
        }
      }
    }

    unless (scalar <$file_directory/*>){ # remove directory if empty
      rmdir($file_directory);
    }
  }

  if (-d $parent_directory){
    unless (scalar <$parent_directory/*>){ # remove directory if empty
      rmdir($parent_directory);
    }
  }

  # Then remove data from ticket database
  if (ref $ticket->analysis){ $ticket->analysis->delete; }
  if (ref $ticket->sub_job){ $ticket->sub_job([]); }
  if (ref $ticket->result){$ticket->result([]);}
  $ticket->save;
  $ticket->delete;

  return;
}

sub error_message {
  my ($self, $ticket) = @_;
  my $job_adaptor = $self->hive_adaptor->get_AnalysisJobAdaptor;
  #my $job_message_adaptor = $self->hive_adaptor->getJobMessageAdaptor;

  foreach my $job (@{$ticket->sub_job}){
  }
}

#--------------------------------------------------
sub serialise {
#   my ($self, $object) = @_;
# 
#   $object = $self unless $object;
# 
#   delete $object->{data};
#   my $serialised = nfreeze($object);
#   my $serialised_gzip;
#   gzip \$serialised => \$serialised_gzip, -LEVEL => 9 or die "gzip failed: $GzipError";
# 
#   return \$serialised_gzip;
}

sub deserialise {
#   my ($self, $object) = @_;
#   my $gunzipped_and_frozen;
# 
#   gunzip \$object => \$gunzipped_and_frozen or die "gunzip failed: $GunzipError";
#   my $analysis_object = thaw($gunzipped_and_frozen);
#   $analysis_object->{data} = $self->__data();
# 
#   return $analysis_object;
}

sub retrieve_analysis_object {
  my $self = shift;
  my $ticket = $self->ticket;
  return undef unless $ticket;

  my $analysis_adaptor  = $self->rose_manager(qw(Tools Analysis));
  my $serialised_object = $analysis_adaptor->retrieve_analysis_object($ticket->ticket_id);
  return undef unless $serialised_object;

  my $analysis_object = $self->deserialise($serialised_object);
  return $analysis_object
}

sub get_time_now {
  my $self = shift;
  my ($sec, $min, $hour, $day, $mon, $year) = localtime();
  my $now = (1900+$year).'-'.sprintf('%02d', $mon+1).'-'.sprintf('%02d', $day).' '
              .sprintf('%02d', $hour).':'.sprintf('%02d', $min).':'.sprintf('%02d', $sec);
  return $now;
}

sub get_unique_ticket_name {
  my $self = shift;
  my $unique;

  while (!$unique ) {
   my $template = "BLA_XXXXXXXX";
   $template =~ s/X/['0'..'9','A'..'Z','a'..'z']->[int(rand 54)]/ge;
   unless ($self->rose_manager(qw(Tools Ticket))->fetch_ticket_by_name($template)) {
    $unique = $template;
   }
  }

  return $unique;
}

#--------------------- Blast result calls ? may not belong here!

sub get_blast_method {
  my $self  = shift;
  my $analysis_object = $self->retrieve_analysis_object;
  my $method = $analysis_object->{'_methods'};
  return $method;
}

sub get_hit_db_entry {
  my ($self, $result_id) = @_;
  my $result_adaptor  = $self->rose_manager(qw(Tools Result));
  my $result_entry = shift @{$result_adaptor->fetch_result_by_result_id($result_id)};
  return $result_entry;
}

sub get_job_division_data {
  my ($self, $result_entry) = @_;
  my $frozen_division = $result_entry->sub_job->job_division;
  my $job_division = $self->deserialise($frozen_division);
  return $job_division;
}

sub fetch_blast_hit_by_id {
  my ($self, $result_id) = @_;

  # retrieve hit
  my $result_entry = $self->get_hit_db_entry($result_id);
  my $frozen_hit = $result_entry->result;
  my $hit = $self->deserialise($frozen_hit);
  return $hit;
}

sub get_hit_species {
  my ($self, $result_id)  = @_;

  # retrieve hit
  my $result_entry = $self->get_hit_db_entry($result_id);
  my $frozen_hit = $result_entry->result;
  my $hit = $self->deserialise($frozen_hit);

  my $job_division = $self->get_job_division_data($result_entry);
  my $species = $job_division->{'species'};

  return $species;
}

sub get_ticket_hits_by_coords{
  my ($self, $coords, $ticket_id, $species) = @_;

  my $slice_adaptor = $self->database('core', $species)->get_SliceAdaptor;
  my $slice = $slice_adaptor->fetch_by_toplevel_location($coords);

  return $self->get_all_hits_from_ticket_in_region($slice, $ticket_id);
}

sub get_all_hits_from_ticket_in_region {
  my ($self, $slice, $id) = @_;
  my $ticket_id = $id || $self->ticket->ticket_id;
  my @aligned_hits;


  my $result_adaptor = $self->rose_manager(qw(Tools Result));
  my @result_objects = @{$result_adaptor->fetch_all_results_in_region($ticket_id, $slice)};
  foreach (@result_objects) {
    my $frozen_gzipped_hit = $_->result;
    my $hit = $self->deserialise($frozen_gzipped_hit);
    push @aligned_hits, [$_->result_id, $hit];
  }

  return \@aligned_hits;
}


sub map_btop_to_genomic_coords {
  my ($self, $hit, $result_id) = @_;

  return $hit->{'galn'} if $hit->{'galn'};

  my $result = $self->get_hit_db_entry($result_id);

  my $btop = $hit->{'aln'};
  chomp $btop;
  my $genomic_btop;
  my $coords = $hit->{'g_coords'} || undef;

  #### temp for testing! ####
  $hit->{'db_type'} = 'cdna';

  my $target_object = $self->get_target_object($hit);
  my $mapping_type = $hit->{'db_type'} =~/pep/i ? 'pep2genomic' : 'cdna2genomic';


  my $gap_start = $coords->[0]->end;
  my $gap_count = scalar @$coords;
  my $processed_gaps = 0;

  # reverse btop string if necessary so always dealing with + strand genomic coords
  my $object_strand = $target_object->isa('Bio::EnsEMBL::Translation') ? $target_object->translation->start_Exon->strand :
                      $target_object->strand;

  my $rev_flag = $object_strand ne $hit->{'tori'} ? 1 : undef;

  $btop = $self->reverse_btop($btop) if $rev_flag;

  # account for btop strings that do not start with a match;
  $btop = '0'.$btop  if $btop !~/^\d+/ ;


  $btop =~s/(\d+)/:$1:/g;
  $btop =~s/^:|:$//g;
  my @btop_features = split (/:/, $btop);

  my $genomic_start = $hit->{'gstart'};
  my $genomic_end   = $hit->{'gend'};
  my $genomic_offset = $genomic_start;
  my $target_offset  = !$rev_flag ? $hit->{'tstart'} : $hit->{'tend'};

  while (scalar @btop_features > 0){
    my $num_matches = shift @btop_features;
    my $diff_string = shift @btop_features;
    next unless $diff_string;

    my $diff_length = (length $diff_string) / 2;
    my $temp = $diff_string;
    my @diffs = (split //, $temp);

    # Account for bases inserted in query relative to target
    my $insert_in_query = 0;

    while (defined( my $query_base = shift @diffs)){
      my $target_base = shift @diffs;
      $insert_in_query++ if $target_base eq '-' && $query_base ne '-';
    }

    my ($difference_start, $difference_end);

    if ($rev_flag) {
      $difference_end = $target_offset - $num_matches;
      $difference_start = $difference_end - $diff_length + $insert_in_query + 1;
      $target_offset = $difference_start -1;
    } else {
      $difference_start = $target_offset + $num_matches;
      $difference_end  = $difference_start + $diff_length - $insert_in_query -1;
      $target_offset = $difference_end +1;
    }
;

    my @mapped_coords = ( sort { $a->start <=> $b->start }
                          grep { ! $_->isa('Bio::EnsEMBL::Mapper::Gap') }
                          $target_object->$mapping_type($difference_start, $difference_end, $hit->{'tori'} )
                        );

    my $mapped_start = $mapped_coords[0]->start;
    my $mapped_end   = $mapped_coords[-1]->end;
;

    # Check that mapping occurs before the next gap
    if ($mapped_start < $gap_start && $mapped_end <= $gap_start){
      $genomic_btop .= $num_matches;
      $genomic_btop .= $diff_string;
      $genomic_offset = $mapped_end +1;
    } elsif ($mapped_start > $gap_start){

      # process any gaps in mapped genomic coords first
      while ($mapped_start > $gap_start){
        my $matches_before_gap = $gap_start - $genomic_offset + 1;
        my $gap_end = $coords->[$processed_gaps + 1]->start -1;
        my $gap_length = ($gap_end - $gap_start);
        my $gap_string = '--'x $gap_length;
        $genomic_offset = $gap_end + 1;
        $genomic_btop .= $matches_before_gap;
        $genomic_btop .= $gap_string;

        $processed_gaps++;
        $gap_start = $coords->[$processed_gaps]->end || $genomic_end;
      }

      # Add difference info
      my $matches_after_gap = $mapped_start - $genomic_offset;
      $genomic_btop .= $matches_after_gap;
      $genomic_btop .= $diff_string;
      $genomic_offset = $mapped_end +1;;
    } elsif( $mapped_start < $gap_start && $mapped_end > $gap_start) {
      # Difference in btop string spans a gap in the genomic coords

      my $diff_matches_before_gap = $gap_start - $mapped_start;
      my $diff_index = ( $diff_matches_before_gap * 2 ) -1;
      my $diff_before_gap = join('', @diffs[0..$diff_index]);
      $diff_index++;

      $genomic_btop .= $num_matches;
      $genomic_btop .= $diff_before_gap;


      while ($mapped_end > $gap_start) {
        my $gap_end = $coords->[$processed_gaps + 1]->start -1;
        my $gap_length = ($gap_end - $gap_start);
        my $gap_string = '--'x $gap_length;
        $processed_gaps++;
        $gap_start = $coords->[$processed_gaps]->end || $genomic_end;

        my $match_number = $gap_start - $gap_end;
        my $diff_end = $diff_index + ( $match_number * 2 ) -1;

        my $diff_after_gap = join('', @diffs[$diff_index..$diff_end]);
        $genomic_btop .= $gap_string;
        $genomic_btop .= $diff_after_gap;
        $diff_index = $diff_end +1;
      }

      my $diff_after_gap = join('', @diffs[$diff_index..-1]);
      $genomic_btop .= $diff_after_gap;

      $genomic_offset = $mapped_end +1;
    } else {
      warn ">> mapping case not caught!  $mapped_start $mapped_end $gap_start";
    }
  }


  # Add in any gaps from mapping to genomic coords that occur after last btop feature
  while ($gap_count > $processed_gaps +1){
    my $num_matches = $gap_start - $genomic_offset + 1;
    my $gap_end = $coords->[$processed_gaps + 1]->start -1;
    my $gap_length = ($gap_end - $gap_start);
    my $gap_string = '--'x $gap_length;

    $genomic_btop .= $num_matches;
    $genomic_btop .= $gap_string;

    $genomic_offset = $gap_end +1;
    $gap_start = $coords->[$processed_gaps + 1]->end;
    $processed_gaps++;
  }


  my $btop_end =  $genomic_end - $genomic_offset +1;
  $genomic_btop .= $btop_end;

  # Write back to database so we only have to do this once
  $hit->{'galn'} = $genomic_btop;
  delete $hit->{'data'};

#   my $serialised_hit = nfreeze($hit);
#   my $serialised_gzip;
#   gzip \$serialised_hit => \$serialised_gzip, -LEVEL => 9 or die "gzip failed: $GzipError";

#  $result->result($serialised_hit);
  $result->save;

  return $genomic_btop;
}

sub reverse_btop {
  my ($self, $incoming_btop) = @_;
  $incoming_btop = uc($incoming_btop);
  my $reversed_btop = reverse $incoming_btop; #reverse btop orientation. We fix a few more things later
  my @captures = $reversed_btop =~ /(\d+)([-ACTG]*)/xmsg;
  my $new_btop = q{};
  while(1) {
    my $match_number = shift @captures;
    my $btop_states = shift @captures;
    if(length("$match_number") > 1) { #reversing the string means numbers like 15 become 51 so we fix it
      $match_number = reverse $match_number;
    }
    my @doubles = $btop_states =~ /([-ACTG]{2})/xmsg; #pairs of chars are taken
    my $new_btop_states = join(q{}, map { my $v = reverse $_; $v; } @doubles); #we reverse the pairs of chars. map is funny with these things
    $new_btop .= $match_number if $match_number; #only add the match number if it was defined
    $new_btop .= $new_btop_states;
    last if scalar(@captures) == 0;
  }
  return $new_btop;
}

#------------------------------------------------

sub valid_analysis { # check that the analysis param matches an analysis type we have
}


1;
