package EnsEMBL::Web::Command::Tools::Submit;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Command);


sub process {
  my $self   = shift;  
 
  my $object = $self->object;
  my $analysis_type = $object->param('analysis');  
  my $analysis_object = $object->generate_analysis_object($analysis_type);
  my $input_error = $analysis_object->validate_form_input; 

  if ($input_error ){     

    my $data = {
      'functionName' => 'indicateInputError',
      'functionData' => $input_error
    };

    print $self->jsonify($data);

  } else { 
    my $ticket = $analysis_object->create_ticket; 
    $object->submit_job($ticket);

    my $data = {
      'functionName' => 'updateJobsList',
      'functionData' => 'true'
    };

    print $self->jsonify($data);
  }    
}
1;

