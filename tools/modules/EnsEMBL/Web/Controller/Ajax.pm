package EnsEMBL::Web::Controller::Ajax;

### Provides JSON results for blast input form configuration

use strict;

use EnsEMBL::Web::Object::Tools;
use EnsEMBL::Web::ToolsConstants;

sub get_tools_object {
  return new EnsEMBL::Web::Object::Tools;
}

sub blastconfig {
  my ($self, $hub) = @_;
  my $method = $hub->param('blastmethod');
  my $config_options;

  my %blast_constants = EnsEMBL::Web::ToolsConstants::BLAST_CONFIGURATION_OPTIONS; 
  my $options_and_defaults = $blast_constants{'options_and_defaults'};
    
  for my $type ('general', 'scoring', 'filters_and_masking'){

    foreach ( @{$options_and_defaults->{$type}}){
      my ($option, $methods) = @{$_};
      my ($show, $default);
      if ($methods->{lc($method)}){
        $show = 1;
        $default = $methods->{lc($method)};
      } elsif ($methods->{'all'}){
        $show = 1;
        $default = $methods->{'all'};
      } else {
        $show = 0;
      }

      my @settings = ($show, $default);
      $config_options->{$option}  = \@settings;      
    }
  }

  print $self->jsonify($config_options);
}

sub blastinput {
  my ($self, $hub) = @_; 

  my $species = $hub->param('species'); 
  my $query   = $hub->param('query'); 
  my $db_type = $hub->param('db_type');
  my $db_name = $hub->param('db_name'); 
  my $method  = $hub->param('blastmethod'); 

  my $object = $self->get_tools_object;
  my $blast_object = $object->generate_analysis_object('Blast');

  my ($databases, $methods, $selected_db, $selected_me ) = $blast_object->get_blast_form_params(
    $species, $query, $db_type, $db_name, $method,     
  );

  my (@method_options, @database_options);

  foreach my $me (@$methods){ 
    my $selected = $me eq $selected_me ? 'selected="selected"' : '';
    my $option = sprintf ('<option %s value="%s">%s</option>', $selected, $me, $me,);  
    push @method_options, $option;
  }   

  foreach my $db_info (@$databases){
    my $db = $db_info->{'value'}; 
    my $label = $db_info->{'name'};
    my $selected = $db eq $selected_db ? 'selected="selected"' : '';
    my $option = sprintf ('<option %s value="%s">%s</option>', $selected, $db, $label,);  
    push @database_options, $option;
  }

  my $options = {
    'db_name'    => \@database_options,
    'blastmethod'     => \@method_options
  };

  print $self->jsonify($options);
}

sub jobstatus {
  my ($self, $hub) = @_;
  my @ticket_names = $hub->param('ticket');
  my $object = $self->get_tools_object;
  my $options = {};

  foreach  my $ticket_name (@ticket_names){
    my $ticket = $object->fetch_ticket_by_name($ticket_name);    
    my $status = $object->check_submission_status($ticket);

    $options->{$ticket_name} = $status;
  }

  print $self->jsonify($options);  
}

sub deletejob {
  my ($self, $hub) = @_;
  my $ticket_id = $hub->param('ticket');
  my $object = $self->get_tools_object;  
  $object->delete_ticket($ticket_id);

  my $options = {};
  print $self->jsonify($options);
}

1;
