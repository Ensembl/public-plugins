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

package EnsEMBL::Web::Component::Tools::VEP::ResultsSummary;

use strict;
use warnings;
no warnings 'uninitialized';

use Bio::EnsEMBL::Variation::Utils::Constants qw(%OVERLAP_CONSEQUENCES);

use parent qw(EnsEMBL::Web::Component::Tools::VEP);

sub content {
  my $self   = shift;
  my $hub    = $self->hub;
  my $object = $self->object;
  my $ticket = $object->get_requested_ticket;
  
  return '<div><h3>No ticket selected</h3></div>' unless defined $ticket;
  
  my $job    = ($ticket->job)[0];
  
  return '<div><h3>No job selected</h3></div>' unless defined $job;
  
  return $self->job_status($job) if $job->status ne 'done';
  
  my $name = $self->object->parse_url_param->{ticket_name};

  ## We have a ticket!
  my $hide = $self->hub->get_cookie_value('toggle_stats_status') eq 'closed';
  my $html = sprintf ('<h3><a rel ="job_stats" class="toggle set_cookie %s" href="#">Summary statistics for ticket %s:</a></h3>',
    $hide ? 'closed' : 'open',
    $name
  );
  
  $html .= '<input type="hidden" class="panel_type" value="VEPResultsSummary" />';
  $html .= '<div class="job_stats"><div class="toggleable">';

  my $stats = $self->job_statistics;
  
  my $section = 'General statistics';  
  my $general_stats_table = $self->new_table(
    [
      {key => 'category', title => 'Category'},
      {key => 'count',    title => 'Count'    },
    ],
    [map {{category => $_, count => $stats->{$section}->{$_}}} grep {$_ !~ /Lines/} @{$stats->{sort}->{$section}}]
  );
  
  # make a hash of consequence colours
  my $cons =  \%OVERLAP_CONSEQUENCES;

  my $var_styles   = $hub->species_defs->colour('variation');
  my $colourmap    = $hub->colourmap;
  my %colours;
  
  foreach my $con (keys %OVERLAP_CONSEQUENCES) {
    $colours{$con} = $colourmap->hex_by_name($var_styles->{lc $con}->{'default'}) || 'no_colour';
  }
  
  # encode it in JSON to send to the JS
  my $colour_json = $self->jsonify(\%colours);
  $colour_json =~ s/\"/\'/g;
  
  my @inputs = (
    q{<input class="graph_config" type="hidden" name="legendpos" value="'east'" />},
    q{<input class="graph_config" type="hidden" name="legendmark" value="'circle'" />},
    q{<input class="graph_config" type="hidden" name="maxSlices" value="100" />},
    q{<input class="graph_config" type="hidden" name="minPercent" value="0" />},
    '<input class="graph_dimensions" type="hidden" value="[65,85,60]" />',
    '<input class="js_param" type="hidden" name="cons_colours" value="'.$colour_json.'" />'
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
  $html .= '</div>';
  
  $html .= sprintf('<a class="button edit-button" href="%s">Edit &amp; resubmit</a>',
    $hub->url({
      'type'      => 'Tools',
      'action'    => 'VEP',
      'function'  => 'Edit',
      'tl'        => $ticket->ticket_name
    }),
    $self->img_url
  );
  
  $html .= '<hr/></div></div>';
  
  return $html;
}

sub job_status {
  my $self = shift;
  my $job  = shift;
  
  my $div = $self->dom->create_element('div');
  $div->append_child($self->job_details_table($job, [qw(status results edit delete)]))->set_attribute('class', 'plain-box');

  return $div->render;
  
}

1;
