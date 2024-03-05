=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Job;

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Utils::FileSystem qw(create_path copy_files);
use EnsEMBL::Web::Utils::FileHandler qw(file_put_contents);

sub object  { return shift->{'_object'};  }
sub hub     { return shift->{'_hub'};     }

sub new {
  ## @constructor
  ## @param Web Ticket object
  ## @param Hashref of key-value pairs for columns of the job table row
  ## @param Hashref of input files ($file_name_1 => {'location' => $temp_file_location_1'}, $file_name_2 = {'content' => \@file_content_2})
  my ($class, $web_ticket, $params, $files) = @_;

  return bless {
    '_params'       => $params || {},
    '_object'       => $web_ticket->object,
    '_hub'          => $web_ticket->hub,
    '_input_files'  => $files || {},
    '_rose_object'  => undef
  }, $class;
}

sub get_dispatcher_class {
  ## Gets the dispatcher class name that should be used for this perticulat job
  ## Override this to add any rule to decide which dispatcher should be used
  ## @param Dispatcher data - hashref of data that will be passed to dispatcher
  ## @return Class name suffix for the required dispatcher (to go after EnsEMBL::Web::JobDispatcher::), or undef if default dispatcher should be used
}

sub get_param {
  ## Gets a param value (column value in the table) for the job
  ## @param Valid column name for tools.job table
  my ($self, $param_name) = @_;
  my $rose_job = $self->rose_object;
  return $rose_job ? $rose_job->$param_name : $self->{'_params'}{$param_name};
}

sub set_params {
  ## Sets params values for the job
  ## @param Hashref with keys as valid column name for tools.job table to their corresponding values being set
  my ($self, $params) = @_;
  my $rose_job = $self->rose_object;
  for (keys %$params) {
    $rose_job->$_($params->{$_}) if $rose_job;
    $self->{'_params'}{$_} = $params->{$_};
  }
}

sub rose_object {
  ## Gets the linked rose object for the job (will create a new unsaved one if not already existing)
  ## @return ORM::EnsEMBL::DB::Tools::Job object
  my $self = shift;
  return $self->{'_rose_object'} ||= $self->object->rose_manager((qw(Tools Job)))->object_class->new(%{$self->{'_params'}});
}

sub params {
  ## Gets all param for the job 
  ## @return Hashref with keys as column names, and values as (potential) column values
  my $self = shift;
  return $self->{'_params'};
}

sub prepare_to_dispatch {
  ## Processes the job data to make it ready to be submitted to job dispatcher
  ## Override to make some manipulation to job data before submitting it
  ## The manipulated data then gets saved as dispatcher_data in the same job object
  ## @return Hashref as to be passed to job dispatcher
  return shift->rose_object->job_data->raw;
}

sub save {
  ## Saves the linked rose object to the database
  ## @params As accepted by Rose::DB::Object->save
  my $self      = shift;
  my $rose_job  = $self->rose_object or throw exception('DataObjectMissing', 'Call to save() without existance of mapped rose object');
  return $rose_job->save(@_);
}

sub different_tmp {
  ## Returns location for storing jobs files if you want it to be different from ENSEMBL_TMP
  ## Overwritten/Implemented in each tool Job.pm

  return "";
}

sub create_work_dir {
  ## Creates the directory path for the job, and move its input files to that directory
  ## @param Hashref with following keys:
  ##  - ticket_type : Ticket type name
  ##  - ticket_name : Ticket name
  ##  - persistent  : Flag to tell whether the ticket dir will be persistent, or will need to be cleaned after some age
  ##  - job_number  : Unique number given to the job to differentiate from other jobs
  ## @return Absolute path to the work dir
  my ($self, $params) = @_;

  my $sd    = $self->hub->species_defs;
  my $files = $self->{'_input_files'};
  my $dir   = join '/',
    $self->different_tmp ? $self->different_tmp : $sd->ENSEMBL_TMP_DIR_TOOLS,
    $params->{'persistent'} ? 'persistent' : 'temporary',
    $sd->ENSEMBL_TMP_SUBDIR_TOOLS,
    $params->{'ticket_type'},
    ($params->{'ticket_name'} =~ m|^(.{1})(.{1})(.{1})(.+)$|),
    $params->{'job_number'};

  # clean grouped directory separators
  $dir =~ s|/+|/|;

  # Create the work directory
  create_path($dir);
  $self->set_sandbox_permission($dir); #this is only used for sandbox; making the tools sub dir group writeable so beekeeper dev can write to it

  # Create input file if file content was provided in 'content' key
  file_put_contents("$dir/$_", (delete $files->{$_})->{'content'}) for grep { exists $files->{$_}{'content'} } keys %$files;

  # Copy files if temporary file location was provided
  copy_files({ map { $files->{$_}{'location'} ? ($files->{$_}{'location'} => "$dir/$_") : () } keys %$files }) if keys %$files;

  # add an info file in the dir containing some extra debug info
  my $db = $self->rose_object->init_db;
  file_put_contents(
    sprintf('%s/info.%s', $dir, $params->{'ticket_name'}),
    sprintf("Ticket: %s\n", $params->{'ticket_name'}),
    sprintf("Species: %s\n", $self->get_param('species')),
    sprintf("Assembly: %s\n", $self->get_param('assembly')),
    sprintf("Database: %s@%s:%s\n", $db->database, $db->host, $db->port),
    sprintf("Website: %s\n", $sd->ENSEMBL_SERVERNAME),
    sprintf("Release: %s\n", $sd->ENSEMBL_VERSION),
    sprintf("Server time: %s\n", $self->object->get_time_now)
  );

  return $dir;
}

sub set_sandbox_permission {
  my ($self, $dir) = @_;
#implemented in dev plugins
}

1;
