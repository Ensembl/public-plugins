package EnsEMBL::Web::Object::VEP;

### NAME: EnsEMBL::Web::Object::VEP
### Object for accessing VEP back end 

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
use Bio::EnsEMBL::Registry;
use EnsEMBL::Web::SpeciesDefs;
use EnsEMBL::Web::ExtIndex;
use EnsEMBL::Web::TmpFile::Text;
use Bio::EnsEMBL::Variation::Utils::VEP qw(detect_format);

our $VERBOSE = 1;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new( @_ );
  $self->{'_analysis'}    = 'VEP';
  $self->{'_species'}     = '';
  $self->{'_error'}       = {};
  $self->{'_description'} = '';
  $self->{'_config'}      = {};

  return $self;
}

sub create_jobs {
  my ($self, $ticket) = @_;

  my $hive_adaptor = $self->hive_adaptor;
  my $job_adaptor = $hive_adaptor->get_AnalysisJobAdaptor;
  my $analysis_name = $ticket->job_type->name;
  my $hive_analysis = $hive_adaptor->get_AnalysisAdaptor->fetch_by_logic_name_or_url($analysis_name);    
  my @hive_jobs = ();
  
  my $species = $self->{'_species'};

  # add DB connection params
  my $dba = $self->hub->database('core', $species);
  my $dbc = $dba->dbc;
  my $config = $self->{'_config'};
  $config->{user} = $dbc->username;
  $config->{host} = $dbc->host;
  $config->{port} = $dbc->port;
  $config->{pass} = $dbc->password if $dbc->password;

  my %input = (
    ticket        => $ticket->ticket_id,
    ticket_name   => $ticket->ticket_name,
    species       => lc($species),
    config        => $self->{'_config'},
    ticket_dbc    => {
      -user             => $self->species_defs->DATABASE_WRITE_USER,
      -pass             => $self->species_defs->DATABASE_WRITE_PASS,
      -host             => $self->species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
      -port             => $self->species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
      -dbname           => $self->species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'}
    }
  );

  # Pass job to ensembl-hive 
  my $job_id = $job_adaptor->CreateNewJob(
    -input_id => \%input,
    -analysis => $hive_analysis,
  );

  my $job_division = {
    species => $species,
  };

  my $serialised_division = $self->serialise($job_division);  
  push (@hive_jobs, {
    ticket_id => $ticket->ticket_id,
    sub_job_id => $job_id,
    job_division => $$serialised_division
  }) if $job_id != 0;
  
  $ticket->sub_job(\@hive_jobs);
  $ticket->save(cascade => 1);
  $self->check_submission_status($ticket);

  return;
}

sub get_unique_ticket_name {
  my $self = shift;
  my $unique;

  while (!$unique ) {
   my $template = "VEP_XXXXXXXX";
   $template =~ s/X/['0'..'9','A'..'Z','a'..'z']->[int(rand 54)]/ge;  
   unless ($self->rose_manager(qw(Tools Ticket))->fetch_ticket_by_name($template)) {
    $unique = $template;
   }
  }
    
  return $unique;
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



##----------------------------------------------------------- Form input validation
sub validate_form_input {
  my $self = shift;
  my $cmnd = shift;
  
  $self->process_species;
  $self->process_input_data($cmnd);
  $self->process_description; 
  $self->process_config;
  $self->configure_script_output;
  
  use Data::Dumper;
  $Data::Dumper::Maxdepth = 3;
  warn Dumper $self->{'_error'};

  return keys %{$self->{'_error'}} ? $self->{'_error'} : undef;
}

sub process_species {
  my $self = shift;
  $self->{'_species'} = $self->param('species');
  return;
}

sub process_input_data {
  my $self = shift;
  my $cmnd = shift;
  
  my $hub = $self->hub;
  my $format = $self->param('format');
  $self->param(text => $self->param('text_'.$format));
  
  my ($method) = grep $self->param($_), qw(file url text);
  
  $self->{_file_description} = $self->param('name') || ($method eq 'text' ?
    'pasted data' : ($method eq 'url' ?
      'data from URL' : sprintf("%s", $self->param('file'))));
    
  if ($method) {
    
    # use generic upload method from $cmnd
    # $cmnd is a EnsEMBL::Web::Command::UserData
    my $response = $cmnd->upload($method);
    
    if($response && $response->{'code'}) {
      
      my $code = $response->{'code'};
      
      # use hub methods to retrieve a TmpFile object with the data
      my $tempdata = $hub->session->get_data(type => 'upload', code => $response->{code});
      
      if($tempdata && $tempdata->{'filename'}) {
        my $file = EnsEMBL::Web::TmpFile::Text->new(filename => $tempdata->{'filename'});
        
        # check file format
        my $detected_format;
        
        open IN, $file->{'full_path'};
        while(<IN>) {
          next if /^\#/;
          $detected_format = detect_format($_);
          last if $detected_format;
        }
        close IN;
        
        $self->{'_error'}{'format'} = "Selected file format ($format) does not match detected format ($detected_format)" if $format ne $detected_format;
        
        # store full path for script to use
        $self->{'_config'}->{'input_file'} = $file->{'full_path'};
      }
      else {
        $self->{'_error'}{'file'} = "Could not find file with code ".$code;
      }
    }
    elsif($response && $response->{'error'}) {
      $self->{'_error'}{'url'} = $response->{error};
    }
    else {
      $self->{'_error'}{'file'} = 'Upload failed: '.$response->{filter_code};
    }
  }
  else {
    $self->{'_error'}{'file'} = 'No input data has been entered';
  }
}

sub process_description {
  my $self = shift;

  my $desc = 'VEP analysis of '.$self->{_file_description}.' in '.$self->{_species};

  $self->{'_description'} = $desc;
}

sub process_config {
  my $self = shift;
  
  my $config = $self->{_config};
  
  # file format
  $config->{format} = $self->param('format');
  
  # species
  my $species = $self->{'_species'};
  $config->{species} = lc($species);
  
  # refseq
  $config->{refseq} = 'yes' if $self->param('core_type_'.$species) eq 'refseq';
  
  # filters
  my $frequency_filtering = $self->param('frequency');
  
  if($species eq 'Homo_sapiens') {
    if($frequency_filtering eq 'common') {
      $config->{filter_common} = 'yes';
    }
    elsif($frequency_filtering eq 'advanced') {
      $config->{check_frequency} = 'yes';
      $config->{$_} = $self->param($_) for qw(freq_pop freq_freq freq_gt_lt freq_filter);
    }
  }
  
  my $summary = $self->param('summary');
  if($summary ne 'no') {
    $config->{$summary} = 'yes';
  }
  
  # species-dependent
  foreach my $p(qw(regulatory sift polyphen)) {
    my $value = $self->param($p.'_'.$species);
    $config->{$p} = $value if $value && $value ne 'no';
  }
  
  # check existing
  my $check_ex = $self->param('check_existing_'.$species);
  
  if($check_ex) {
    if($check_ex eq 'yes') {
      $config->{check_existing} = 'yes';
    }
    elsif($check_ex eq 'allele') {
      $config->{check_existing} = 'yes';
      $config->{check_alleles} = 'yes';
    }
    
    # MAFs in human
    if($species eq 'Homo_sapiens') {
      $config->{gmaf} = 'yes' if $self->param('gmaf_'.$check_ex) eq 'yes';
      $config->{maf_1kg} = 'yes' if $self->param('maf_1kg_'.$check_ex) eq 'yes';
      $config->{maf_esp} = 'yes' if $self->param('maf_esp_'.$check_ex) eq 'yes';
    }
  }
  
  # extra and identifiers
  for(qw(numbers canonical domains biotype hgnc ccds protein hgvs coding_only)) {
    $config->{$_} = $self->param($_) if $self->param($_);
  }
}

# configure output files
sub configure_script_output {
  my $self = shift;
  
  # create output and stats file
  my $output_file = $self->output_file;
  my $stats_file = $self->stats_file;
  
  $self->{_config}->{output_file} = $output_file->{full_path};
  $self->{_config}->{stats_file}  = $stats_file->{full_path};
}

sub stats_file {
  my $self = shift;
  return $self->_tmp_file('stats', @_);
}

sub output_file {
  my $self = shift;
  return $self->_tmp_file('output', 'VcfTabix', @_);
}

sub _tmp_file {
  my $self = shift;
  my $type = shift;
  my $class = shift;
  
  my $hash_key = sprintf("_%s_file", $type);
  $class ||= 'Text';
  my $class_path = 'EnsEMBL::Web::TmpFile::'.$class;
  
  if(!defined($self->{$hash_key})) {
    my $file = $class_path->new(prefix => 'vep');
    
    # initialise path and file, VEP will overwrite
    my $path = $file->full_path;
    ($file->drivers)[0]->make_directory($path);
    
    $self->{$hash_key} = $file;
  }
  
  return $self->{$hash_key};
}


# post-run methods

sub job_statistics {
  my $self = shift;
  my $stats_file_obj = $self->stats_file;
  
  my $stats = {};
  my $section;
  
  for(split /\n/, $stats_file_obj->content) {
    if(m/^\[(.+?)\]$/) {
      $section = $1;
    }
    elsif(/\w+/) {
      my ($key, $value) = split "\t";
      $stats->{$section}->{$key} = $value;
      push @{$stats->{sort}->{$section}}, $key;
    }
  }
  
  return $stats;
}

1;
