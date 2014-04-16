=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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
use EnsEMBL::Web::Tools::FileSystem qw(create_path copy_files);

sub object  { return shift->{'_object'};  }
sub hub     { return shift->{'_hub'};     }

sub new {
  ## @constructor
  ## @param Web Ticket object
  ## @param Hashref of key-value pairs for columns of the job table row
  ## @param Hashref of input files (destined file name => file temp location)
  my ($class, $web_ticket, $params, $files) = @_;

  return bless {
    '_params'       => $params || {},
    '_object'       => $web_ticket->object,
    '_hub'          => $web_ticket->hub,
    '_io_files'     => $files || {},
    '_rose_object'  => undef
  }, $class;
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

sub create_work_dir {
  ## Creates the directory path for the job, and move it's input files to that directory
  ## @param Hashref with following keys:
  ##  - ticket_type : Ticket type name
  ##  - ticket_name : Ticket name
  ##  - persistent  : Flag to tell whether the ticket dir will be persistent, or will need to be cleaned after some age
  ##  - job_number  : Unique number given to the job to differentiate from other jobs
  ## @return Absolute path to the work dir
  my ($self, $params) = @_;

  my $files = $self->{'_io_files'};

  my $dir = join '/', $self->hub->species_defs->ENSEMBL_TOOLS_TMP_DIR, ($params->{'persistent'} ? 'persistent' : 'temporary'), $params->{'ticket_type'}, ($params->{'ticket_name'} =~ /.{1,3}/g), $params->{'job_number'};

  create_path($dir);
  copy_files({ map {$files->{$_} => "$dir/$_"} keys %$files }) if keys %$files;

  return $dir;
}

1;
