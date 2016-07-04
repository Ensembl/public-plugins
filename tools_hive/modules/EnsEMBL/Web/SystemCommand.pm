=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::SystemCommand;

### Wrapper around system()

use strict;
use warnings;

sub new {
  ## @constructor
  ## @param Calling RunnableDB instance
  ## @param Command string
  ## @param Options hashref OR hash in ArrayRef syntax if order is to be maintained OR just a string
  ## @param Hashref of error codes to error messages
  my ($class, $runnable, $command, $options, $error_message_map) = @_;
  return bless {
    'runnable'  => $runnable,
    'command'   => $command,
    'options'   => $options || '',
    'error_map' => $error_message_map || {}
  }, $class;
}

sub error_code      { return shift->{'error_code'};     }
sub error_message   { return shift->{'error_message'};  }

sub execute {
  ## Executes the command by making a system call
  ## @param Hashref with following keys
  ##  - output_file Name of the file to capture the output (optional)
  ##  - log_file    Name of the file to capture error logs (optional)
  ## @return the command object itself
  my ($self, $params) = @_;

  my $options = $self->{'options'};
  my $command = join ' ',
    $self->{'command'},
    ref $options
      ? ref $options eq 'ARRAY'
      ? @$options                                                 #ARRAY
      : map({( $_, $options->{$_} // () )} keys %$options)        #HASH
      : $options,                                                 #STRING
    $params->{'output_file'}  ? ">$params->{'output_file'}" : (),
    $params->{'log_file'}     ? "2>$params->{'log_file'}"   : ()
  ;

  $self->{'runnable'}->warning("SystemCommand Executing: $command");

  system($command);

  $self->{'error_code'}     = $? >> 8;
  $self->{'error_message'}  = $self->{'error_map'}->{$self->{'error_code'}} || "Unkown error ($self->{'error_code'})";
  $self->{'runnable'}->warning("SystemCommand Error: ($self->{'error_code'}) $self->{'error_message'}") if $self->{'error_code'};

  return $self;
}

1;