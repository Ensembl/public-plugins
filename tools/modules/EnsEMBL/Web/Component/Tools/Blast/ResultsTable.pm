=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;

use parent qw(EnsEMBL::Web::Component::Tools::Blast);

sub buttons {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $job     = $object->get_requested_job({'with_all_results' => 1});

  return unless $job && $job->status eq 'done' && @{$job->result};

  return {
    'class'     => 'export',
    'caption'   => 'Download results file',
    'url'       => $hub->url('Download', {
        '__clear'   => 1,
        'function'  => '',
        'tl'        => $object->create_url_param
    })
  };
}

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $job       = $object->get_requested_job({'with_all_results' => 1});
  my $html      = '';
  my $glossary  = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($hub)->fetch_glossary_lookup;

  if ($job && $job->status eq 'done' && @{$job->result}) {

    my $results     = $job->result;
    my $job_data    = $job->job_data;
    my $species     = $job->species;
    my $source      = $job_data->{'source'};
    my @columns     = ( $source =~/latestgp/i ? (
      { 'key' => 'tid',     'title'=> 'Genomic Location', 'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Genomic Location (BLAST Results)'} },
      { 'key' => 'tori',    'title'=> 'Orientation',      'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Orientation (BLAST Results)'}      }
    ) : (
      { 'key' => 'tid',     'title'=> 'Subject name',     'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Subject name (BLAST Results)'}     },
      { 'key' => 'tstart',  'title'=> 'Subject start',    'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Subject start (BLAST Results)'}    },
      { 'key' => 'tend',    'title'=> 'Subject end',      'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Subject end (BLAST Results)'}      },
      { 'key' => 'tori',    'title'=> 'Subject ori',      'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Subject ori (BLAST Results)'}      },
      { 'key' => 'gid',     'title'=> 'Genomic Location', 'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Genomic Location (BLAST Results)'} },
      { 'key' => 'gori',    'title'=> 'Orientation',      'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Orientation (BLAST Results)'}      }
    ), (
      { 'key' => 'qid',     'title'=> 'Query name',       'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Query name (BLAST Results)'}       },
      { 'key' => 'qstart',  'title'=> 'Query start',      'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Query start (BLAST Results)'}      },
      { 'key' => 'qend',    'title'=> 'Query end',        'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Query end (BLAST Results)'}        },
      { 'key' => 'qori',    'title'=> 'Query ori',        'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Query ori (BLAST Results)'}        },
      { 'key' => 'len',     'title'=> 'Length',           'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Length (BLAST Results)'}           },
      { 'key' => 'score',   'title'=> 'Score',            'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Score (BLAST Results)'}            },
      { 'key' => 'evalue',  'title'=> 'E-val',            'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'E-val (BLAST Results)'}            },
      { 'key' => 'pident',  'title'=> '%ID',              'align' => 'left',  'sort' => 'numeric_hidden', 'help' => $glossary->{'%ID (BLAST Results)'}              }
    ));

    my $table = $self->new_table(\@columns, [], {
      'data_table'      => 1,
      'exportable'      => 0,
      'sorting'         => ['score desc'],
      'hidden_columns'  => [ grep { $columns[$_]->{'key'} eq 'qori' } 0..$#columns ]
    });

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

  my $hub = $self->hub;

  my ($target_url, $gene_url, $gene_label) = $self->object->get_result_url('target', $job, $result);

  return sprintf('<a href="%s">%s</a>%s',
    $hub->url($target_url),
    $result->result_data->{'tid'},
    $gene_url && $gene_label
      ? sprintf(' (Gene: <a href="%s">%s</a>)', $hub->url($gene_url), $gene_label)
      : ''
  );
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
