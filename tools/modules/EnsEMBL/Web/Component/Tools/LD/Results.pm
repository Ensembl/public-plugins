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

package EnsEMBL::Web::Component::Tools::LD::Results;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools::LD);

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use Bio::EnsEMBL::Variation::Utils::Constants qw(%OVERLAP_CONSEQUENCES);
use EnsEMBL::Web::Component::Tools::NewJobButton;

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $object  = $self->object;
  my $ticket  = $object->get_requested_ticket;
  my $job     = $ticket ? $ticket->job->[0] : undef;

  my $cons = \%OVERLAP_CONSEQUENCES;
  my $var_styles = $sd->colour('variation');
  my $colourmap = $hub->colourmap;

  return '' if !$job || $job->status ne 'done';

  my $job_data  = $job->job_data;

  my $job_config  = $job->dispatcher_data->{'config'};

  my $ld_calculation = $job_config->{'ld_calculation'};

  my %header_titles = (
    'VARIANT1' => 'Variant 1',
    'VARIANT2' => 'Variant 2',
    'R2'       => 'r<sup>2</sup>',
    'D_PRIME' => "D'",
    'VARIANT1_LOCATION' => 'Variant 1 location',
    'VARIANT2_LOCATION' => 'Variant 2 location',
    'VARIANT1_CONSEQUENCE' => 'Variant 1 consequence',
    'VARIANT2_CONSEQUENCE' => 'Variant 2 consequence',
    'VARIANT1_EVIDENCES' => 'Variant 1 evidence',
    'VARIANT2_EVIDENCES' => 'Variant 2 evidence',

  );
  my %table_sorts = (
    'R2'      => 'numeric',
    'D_PRIME' => 'numeric',
    'VARIANT1_LOCATION' => 'numeric',
    'VARIANT2_LOCATION' => 'numeric',
  );

  my @rows;
  my @headers = qw/VARIANT1 VARIANT1_LOCATION VARIANT1_CONSEQUENCE VARIANT1_EVIDENCES VARIANT2 VARIANT2_LOCATION VARIANT2_CONSEQUENCE VARIANT2_EVIDENCES R2 D_PRIME/;

  my $species   = $job->species;
  
  my $button_url = $hub->url({'function' => undef, 'expand_form' => 'true'});
  my $new_job_button = EnsEMBL::Web::Component::Tools::NewJobButton->create_button( $button_url );

  my $html      = '';


  my @warnings  = grep { $_->data && ($_->data->{'type'} || '') eq 'LDWarning' } @{$job->job_message};
  $html .= $self->_warning('Some errors occurred while running LD calculations', sprintf '<pre class="tools-warning">%s</pre>', join "\n", map $_->display_message, @warnings) if @warnings;

  my $ticket_name = $object->parse_url_param->{'ticket_name'};

  my $result_headers = $job_config->{'result_headers'};
  my @output_file_names = @{$job_config->{'output_file_names'}};

  # download all results in one file if file available
  my $output_file = $job_config->{'joined_output_file_name'};
  my $output_file_full_path = join('/', $job->job_dir, $output_file); 
  if (-f $output_file_full_path) {
    my @content = file_get_contents($output_file_full_path, sub { s/\R/\r\n/r });
    if (scalar @content) {
      my $down_url  = $object->download_url({output_file => $output_file});
      $html .= qq{<p><div class="component-tools tool_buttons"><a class="export" href="$down_url">Download all results</a><div class="left-margin">$new_job_button</div></div></p>};
    }
  }

  foreach my $output_file (@output_file_names) {
    next if (!-f join('/', $job->job_dir, $output_file));
    my @content = file_get_contents(join('/', $job->job_dir, $output_file), sub { s/\R/\r\n/r });
    my $header = $result_headers->{$output_file};
    if (scalar @content == 0) {
      $html .= qq{<h2>There are no results for $header</h2>};
      next;
    }
    $header = $result_headers->{$output_file};
    $html .= qq{<h2>Results for $header</h2>};
    if ($ld_calculation eq 'center') {
      # print LD Manhattan plot
      my ($population_id, $variant_name) = split('_', $output_file);
      my $manhattan_plot_input = $job_config->{'manhattan_plot_input'};
      my $values = $manhattan_plot_input->{$variant_name};
      my $url = $hub->url({
        type   => 'Variation',
        action => 'LDPlot',
        v      => $values->{'v'},
        vf     => $values->{'vf'},
        pop1   => $values->{'pop1'},
      });
      my $debug = join('-', $values->{'v'}, $values->{'vf'}, $values->{'pop1'});
      $html .= qq{<p><a class="ld_manplot_link" href="$url">View Linkage disequilibrium plot</a></p>};
    }
    my @rows = ();
    my $preview_count = 10;
    foreach my $line (@content) {
      chomp $line;
      my @split     = split /\t/, $line;
      my %row_data  = map { $headers[$_] => $split[$_] } 0..$#headers;

      for my $title (qw/VARIANT1 VARIANT2/) {
        my $var = $row_data{$title};
        my $url = $hub->url({
          type    => 'Variation',
          action  => 'Explore',
          v       => $var,
          species => $species
        });

        my $zmenu_url = $hub->url({
          type    => 'ZMenu',
          action  => 'Variation',
          v       => $var,
          species => $species
        });

        my $new_value = $self->zmenu_link($url, $zmenu_url, $var);
        $row_data{$title} = $new_value;
      }

      for my $title (qw/VARIANT1_EVIDENCES VARIANT2_EVIDENCES/) {
        my $evidence_values = $row_data{$title};
        my $img_evidence = '';
        foreach my $evidence (split /,/, $evidence_values){
          my $evidence_label = $evidence;
          $evidence_label =~ s/_/ /g;
          $img_evidence .=  sprintf(
            '<img class="_ht" style="margin-right:6px;margin-bottom:-2px;vertical-align:top" src="%s/val/evidence_%s.png" title="%s"/>',
            $self->img_url, $evidence, $evidence_label
          );
        }
        $row_data{$title} = $img_evidence;
      }

      for my $title (qw/VARIANT1_CONSEQUENCE VARIANT2_CONSEQUENCE/) {
        my $con = $row_data{$title};
        if (defined($cons->{$con})) {
          my $colour = $var_styles->{lc $con}
                     ? $colourmap->hex_by_name($var_styles->{lc $con}->{'default'})
                     : $colourmap->hex_by_name($var_styles->{'default'}->{'default'});

          my $new_value = 
            sprintf(
            '<nobr><span class="colour" style="background-color:%s">&nbsp;</span> '.
            '<span class="_ht ht" title="%s">%s</span></nobr>',
            $colour, $cons->{$con}->description, $con
          );
          $row_data{$title} = $new_value;
        }
      }

      if ($preview_count) {
        push @rows, \%row_data;
        $preview_count--;
      } else {
        last;
      }
    }

    my @table_headers = map {{
      'key' => $_,
      'title' => $header_titles{$_} || $_,
      'sort' => $table_sorts{$_} || 'string',
    }} @headers;

    $html .= qq{<p>Preview of the first 10 result rows</p>} if ($preview_count == 0);

    my $table = $self->new_table(\@table_headers, \@rows, { data_table => 1, sorting => [ 'R2 asc' ], exportable => 0, data_table_config => {bLengthChange => 'false', bFilter => 'false'}, });
    $html .= $table->render || '<h3>No data</h3>';


    my $down_url  = $object->download_url({output_file => $output_file});

    $html .= qq{<p><div class="component-tools tool_buttons"><a class="export" href="$down_url">Download</a></div></p>};
  }
  return $html;
}

sub zmenu_link {
  my ($self, $url, $zmenu_url, $html) = @_;
  return sprintf('<a class="_zmenu" href="%s">%s</a><a class="hidden _zmenu_link" href="%s"></a>', $url, $html, $zmenu_url);
}

1;
