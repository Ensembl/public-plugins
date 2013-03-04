package EnsEMBL::Web::Component::Tools;

use strict;

use base qw(EnsEMBL::Web::Component);


sub select_ticket {
  my ($self, $type, $error) = @_;
  
  my $html = '<h2>Select a ticket to see results:</h2>';
  if ($error){ $html .= "<p class='error space-below'>$error </p>";}
  $html .= 'Please select a ticket from recent jobs table or enter a ticket name into the search box below to display results for that ticket:';

  my $action = $type . 'Results';
  my $url = $self->hub->url({ type => 'Tools', action => $action} );
  $html .= qq{
    <div>
    <form action="$url" method="get">
    <input id="ticket" name="tk" />
    <input type="submit" value="Go" class="input-submit" />
    </form>
    </div>
  }; 

  return $html;
}

sub get_download_link {
  my ($self, $ticket, $format, $filename) = @_;
  my $hub = $self->hub;

  my $url = $hub->url({
    'type'    => 'Tools',
    'format'  => $format,
    'action'  => 'Download',
    'tk'      => $ticket,
    'file'    => $filename,
    '_format' => 'Text'
  });

  return $url;  
}

sub failure_message {
  my ($self, $ticket) = @_;
  my $analysis = $ticket->job->job_name;  
  my $error = $self->object->error_message($ticket); 

  return $self->_error(
    $analysis . ' Failed',
    '<p>Unknown error</p>'
  );
}

sub pointer_default {
  my ($self, $feature_type) = @_;

  my %hash = (
    Blast           => [ 'rharrow', 'gradient', [qw(90 gold orange chocolate firebrick darkred)]],
  );

  return $hash{$feature_type};
}

sub gradient {
  my $self = shift;

  my %pointer_defaults = EnsEMBL::Web::ToolsConstants::KARYOTYPE_POINTER_DEFAULTS;
  my $defaults    = $pointer_defaults{'Blast'};
  my $colour    = $defaults->[1];
  my $gradient  = $defaults->[2];

  return $gradient;
}

1;

