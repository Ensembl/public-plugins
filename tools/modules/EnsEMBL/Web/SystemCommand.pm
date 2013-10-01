package EnsEMBL::Web::SystemCommand;

### Wrapper around system() method

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
  ##  - debug       Flag if on, will print the debug info to STDERR (not to the log file even if provided) (optional)
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
  $self->{'error_message'}  = $self->{'error_map'}->{$self->{'error_code'}};
  $self->{'runnable'}->warning("SystemCommand Error: ($self->{'error_code'}) $self->{'error_message'}") if $self->{'error_code'};

  return $self;
}

1;