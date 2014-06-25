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

package EnsEMBL::Web::Component::Tools::Blast::ResultsTable;

### Component to display a table for all the results of a single blast job

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools::Blast);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $job       = $object->get_requested_job({'with_all_results' => 1});
  my $html      = '';

  if ($job && $job->status eq 'done' && @{$job->result}) {

    my $results     = $job->result;
    my $job_data    = $job->job_data;
    my $species     = $job->species;
    my $source      = $job_data->{'source'};
    my $table       = $self->new_table($source =~/latestgp/i
      ? [
          { 'key' => 'tid',     'title'=> 'Genomic Location', 'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'tori',    'title'=> 'Orientation',      'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'qid',     'title'=> 'Query name',       'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'qstart',  'title'=> 'Query start',      'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'qend',    'title'=> 'Query end',        'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'qori',    'title'=> 'Query ori',        'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'len',     'title'=> 'Length',           'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'score',   'title'=> 'Score',            'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'evalue',  'title'=> 'E-val',            'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'pident',  'title'=> '%ID',              'align' => 'left',  'sort' => 'numeric' },
        ]
      : [
          { 'key' => 'tid',     'title'=> 'Subject name',     'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'tstart',  'title'=> 'Subject start',    'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'tend',    'title'=> 'Subject end',      'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'tori',    'title'=> 'Subject ori',      'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'gid',     'title'=> 'Genomic Location', 'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'gori',    'title'=> 'Orientation',      'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'qid',     'title'=> 'Query name',       'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'qstart',  'title'=> 'Query start',      'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'qend',    'title'=> 'Query end',        'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'qori',    'title'=> 'Query ori',        'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'len',     'title'=> 'Length',           'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'score',   'title'=> 'Score',            'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'evalue',  'title'=> 'E-val',            'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'pident',  'title'=> '%ID',              'align' => 'left',  'sort' => 'numeric' },
        ],
      [], {'data_table' => 1, 'exportable' => 0, 'sorting' => ['score desc']}
    );

    # Data for table rows
    for (@$results) {
      my $result_id     = $_->result_id;
      my $result_data   = $_->result_data->raw;
      my $url_param     = $object->create_url_param({'result_id' => $result_id});
      my $location_link = $self->location_link($job, $_);

      $result_data->{'options'} = {'class' => "hsp_$result_id"};

      # orientation
      $result_data->{$_} = $result_data->{$_} == 1 ? 'Forward' : 'Reverse' for grep m/ori$/, keys %$result_data;

      if ($source =~ /latestgp/i) {
        $result_data->{'tid'} = $location_link;
      } else {
        $result_data->{'gid'} = $location_link;
        $result_data->{'tid'} = $self->target_link($job, $_);
      }

      # add links to query name and pid columns
      $result_data->{'qid'} = sprintf('<span>%s</span>&nbsp;<a href="%s" class="small _ht" title="View Query Sequence">[Sequence]</a>',
        $result_data->{'qid'},
        $hub->url($object->get_result_url('query_sequence', $job, $_))
      );
      $result_data->{'pident'} = sprintf('<span>%s</span>&nbsp;<a href="%s" class="small _ht" title="View Alignment">[Alignment]</a>',
        $result_data->{'pident'},
        $hub->url($object->get_result_url('alignment', $job, $_))
      );

      $table->add_row($result_data);
    }

    $html .= sprintf '<h3><a rel="_blast_results_table" class="toggle _slide_toggle set_cookie open" href="#">Results table</a></h3>
      <div class="_blast_results_table toggleable">%s</div>', $table->render;
  }

  return $html;
}

sub target_link {
  ## Gets the link for the target column
  my ($self, $job, $result) = @_;

  return sprintf '<a href="%s">%s</a>', $self->hub->url($self->object->get_result_url('target', $job, $result)), $result->result_data->{'tid'};
}

sub location_link {
  ## Gets a link to the location view page for the given result
  my ($self, $job, $result) = @_;

  my $hub         = $self->hub;
  my $result_data = $result->result_data;
  my $url         = $self->object->get_result_url('location', $job, $result);
  my $region      = sprintf '%s:%s-%s', $result_data->{'gid'}, $result_data->{'gstart'}, $result_data->{'gend'};

  return sprintf('<a href="%s" class="_ht" title="Region in Detail">%s</a>&nbsp;<a href="%s" class="small _ht" title="View Genomic Sequence">[Sequence]</a>',
    $hub->url($url),
    $region,
    $hub->url($self->object->get_result_url('genomic_sequence', $job, $result))
  );
}

1;
