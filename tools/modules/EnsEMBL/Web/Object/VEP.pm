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
use EnsEMBL::Web::Command::UserData;

our $VERBOSE = 1;

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( @_ );

  $self->{'_error'}       = {};
  $self->{'_analysis'}    = {};
  $self->{'_species'}     = ();
  $self->{'_description'} = '';
  $self->{'_config'} = {};

  return $self;
}

sub ticket_prefix {
  ## Abstract method implementation
  return 'VEP_';
}

sub ticket_type {
  ## Abstract method implementation
  return 'VEP';
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

sub process_job_for_hive_submission {
  ## Abstract method implementation
  my ($self, $job) = @_;

  my $job_data = $job->job_data->raw;

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

  return $job_data;
}



##----------------------------------------------------------- Form input validation
sub form_inputs_to_jobs_data {
  my $self = shift;
  
  $self->process_species;
  $self->process_input_data;
  $self->process_description; 
  $self->process_config;
  $self->configure_script_output;
  #return keys %{$self->{'_error'}} ? $self->{'_error'} : undef;
  
  return [{
    'job_desc'    => $self->{description},
    'species'     => $self->{species},
    'config'      => $self->{_config}
  }];
}

sub process_species {
  my $self = shift;
  $self->{'species'} = $self->param('species');
  return;
}

sub process_input_data {
  my $self = shift;
  
  my $hub = $self->hub;
  my $cmnd = EnsEMBL::Web::Command::UserData->new({object => $self, hub => $hub});
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

  my $desc = 'VEP analysis of '.$self->{_file_description}.' in '.$self->{species};

  $self->{'description'} = $desc;
}

sub process_config {
  my $self = shift;
  
  my $config = $self->{_config};
  
  # file format
  $config->{format} = $self->param('format');
  
  # species
  my $species = $self->{'species'};
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
  for(qw(numbers canonical domains biotype symbol ccds protein hgvs coding_only)) {
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

sub get_tmp_file_objs {
  my $self = shift;
  my $job    = $self->get_requested_job({'with_all_results' => 1});
  
  return unless defined $job;
  
  my $job_data = $job->job_data;
  return unless $job_data && $job_data->{config};
  
  my $tmp_dir = $self->hub->species_defs->ENSEMBL_TMP_DIR;
  
  foreach my $key(grep {!defined($self->{'_'.$_})} grep {/file/} keys %{$job_data->{config}}) {
    my $class = $key =~ /output/ ? 'VcfTabix' : 'Text';
    my $class_path = 'EnsEMBL::Web::TmpFile::'.$class;
    
    my $file_path = $job_data->{config}->{$key};
    
    # remove tmp dir
    $file_path =~ s!^$tmp_dir!!;
    
    # get prefix
    $file_path =~ s/^(.+?\/)//;
    my $prefix = $1;
    
    my $file_obj = $class_path->new(filename => $file_path, prefix => $prefix);
    
    $self->{'_'.$key} = $file_obj;
  }
}

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
