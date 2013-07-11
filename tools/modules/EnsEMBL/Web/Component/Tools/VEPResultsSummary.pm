package EnsEMBL::Web::Component::Tools::VEPResultsSummary;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);
use EnsEMBL::Web::Form;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self   = shift;
  my $hub    = $self->hub;
  my $object = $self->object;

  return $self->select_ticket('VEP') unless $hub->param('tk');
  
  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  unless ( ref($ticket) ){ 
    my $error = $self->_error('Ticket not found', $ticket, '100%');
    return $self->select_ticket('VEP', $error);
  }
  my $name = $ticket->ticket_name;

  ## We have a ticket!
  my $hide = $self->hub->get_cookie_value('toggle_stats_status') eq 'closed';
  my $html = sprintf ('<h3><a rel ="job_stats" class="toggle set_cookie %s" href="#">Job statistics for ticket %s:</a></h3>',
    $hide ? 'closed' : 'open',
    $name
  );
  
  $html .= '<input type="hidden" class="panel_type" value="VEPResultsSummary" />';
  $html .= '<div class="job_stats"><div class="toggleable">';

  my $status = $ticket->status;
  
  my @hive_jobs = @{$ticket->sub_job};

  return $self->failure_text($ticket) if $status eq 'Failed';
  
  my $vep_object = $object->deserialise($ticket->analysis->object);
  my $stats = $vep_object->job_statistics;
  
  my $section = 'General statistics';  
  my $general_stats_table = $self->new_table(
    [
      {key => 'category', title => 'Category'},
      {key => 'count',    title => 'Count'    },
    ],
    [map {{category => $_, count => $stats->{$section}->{$_}}} @{$stats->{sort}->{$section}}],
  );
  
  my @inputs = (
    '<input type="hidden" class="panel_type" value="PopulationGraph" />',
    q{<input class="graph_config" type="hidden" name="legendpos" value="'east'" />},
    q{<input class="graph_config" type="hidden" name="legendmark" value="'circle'" />},
    q{<input class="graph_config" type="hidden" name="maxSlices" value="100" />},
    q{<input class="graph_config" type="hidden" name="minPercent" value="0" />},
    #q{<input class="graph_config" type="hidden" name="colors" value="[]" />},
    '<input class="graph_dimensions" type="hidden" value="[65,80,60]" />',
  );
  
  my @pie_charts = ('Consequences (all)', 'Coding consequences');
  $html .= '<div class="population_genetics_pie">';
  $html .= '<div style="float:left; margin-right: 5px;">'.$general_stats_table->render.'</div>';
  
  for my $i(0..$#pie_charts) {
    $section = $pie_charts[$i];
    my @values = map { sprintf("[%s,'%s']", $stats->{$section}->{$_}, $_) } sort {$stats->{$section}->{$b} <=> $stats->{$section}->{$a}} keys %{$stats->{$section}};
    my $values_string = join(",", @values);
    next unless $values_string;
    push @inputs, qq{<input type="hidden" class="graph_data" value="[$values_string]" />};
    
    $html .= sprintf('
      <div class="pie_chart_holder">
        <div class="pie_chart" title="%s">
          <h4>%s</h4>
          <div id="graphHolder%i" style="width:350px;height:183px"></div>
        </div>
      </div>', $section, $section, $i);
  }
  $html .= '<div>'.join('', @inputs).'</div>';
  
  
  $html .= '</div><hr/></div></div>';
  
  return $html;
}

sub failure_text {
  my ($self, $ticket) = @_;
  my $html;
  my $ticket_name = $ticket->ticket_name;

  my $text = "<p>The VEP job $ticket_name failed to run sucessfully. The error reported was: </p>";
  $html .= $self->_error('VEP job failed', $text, '100%' );

  return $html;  
}

1;
