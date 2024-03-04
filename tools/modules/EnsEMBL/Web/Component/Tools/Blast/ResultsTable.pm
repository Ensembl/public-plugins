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

package EnsEMBL::Web::Component::Tools::Blast::ResultsTable;

### Component to display a table for all the results of a single blast job

use strict;
use warnings;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;

use parent qw(EnsEMBL::Web::Component::Tools::Blast);
use EnsEMBL::Web::Component::Tools::NewJobButton;


sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $job       = $object->get_requested_job({'with_all_results' => 1});
  
  my $button_url = $hub->url({'function' => undef, 'expand_form' => 'true'});
  my $new_job_button = EnsEMBL::Web::Component::Tools::NewJobButton->create_button( $button_url );

  my $html      = '<div class="component-tools tool_buttons "><a class="export" href="' . $object->download_url . '">Download results file</a><div class="left-margin">' . $new_job_button . '</div></div>';

  if ($job && $job->status eq 'done' && @{$job->result}) {

    my $columns = $self->table_columns($job);
    my @rows    = map $self->table_row($job, $_), @{$job->result};
    my $options = $self->table_options($job);

    $html .= sprintf '<h3><a rel="_blast_results_table" class="toggle _slide_toggle set_cookie open" href="#">Results table</a></h3>
      <div class="_blast_results_table toggleable">%s</div>', $self->new_table($columns, \@rows, $options)->render;
  }

  return $html;
}

sub table_columns {
  ## Returns a list of columns for the results table
  ## @param Job object
  ## @return Arrayref of column as expected by new_table method
  my ($self, $job) = @_;

  my $glossary = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($self->hub)->fetch_glossary_lookup;

  return [ $job->job_data->{'source'} =~/latestgp/i ? (
    { 'key' => 'tid',     'title'=> 'Genomic Location',     'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Genomic Location (BLAST Results)'}           },
    { 'key' => 'gene',    'title'=> 'Overlapping Gene(s)',  'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Overlapping Genes (BLAST Results)'}          },
    { 'key' => 'tori',    'title'=> 'Orientation',          'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Orientation (BLAST Results for genomic)'}    }
  ) : (
    { 'key' => 'tid',     'title'=> 'Subject name',         'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Subject name (BLAST Results)'}               },
    { 'key' => 'gene',    'title'=> 'Gene hit',             'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Gene hit (BLAST Results)'}                   },
    { 'key' => 'tstart',  'title'=> 'Subject start',        'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Subject start (BLAST Results)'}              },
    { 'key' => 'tend',    'title'=> 'Subject end',          'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Subject end (BLAST Results)'}                },
    { 'key' => 'tori',    'title'=> 'Subject ori',          'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Subject ori (BLAST Results)'}                },
    { 'key' => 'gid',     'title'=> 'Genomic Location',     'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Genomic Location (BLAST Results)'}           },
    { 'key' => 'gori',    'title'=> 'Orientation',          'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Orientation (BLAST Results for cDNA/protein)'}}
  ), (
    { 'key' => 'qid',     'title'=> 'Query name',           'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Query name (BLAST Results)'}, 'hidden' => 1  },
    { 'key' => 'qstart',  'title'=> 'Query start',          'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Query start (BLAST Results)'}                },
    { 'key' => 'qend',    'title'=> 'Query end',            'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Query end (BLAST Results)'}                  },
    { 'key' => 'qori',    'title'=> 'Query ori',            'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Query ori (BLAST Results)'},  'hidden' => 1  },
    { 'key' => 'len',     'title'=> 'Length',               'align' => 'left',  'sort' => 'numeric_hidden', 'help' => $glossary->{'Length (BLAST Results)'}                     },
    { 'key' => 'score',   'title'=> 'Score',                'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Score (BLAST Results)'}                      },
    { 'key' => 'evalue',  'title'=> 'E-val',                'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'E-val (BLAST Results)'}                      },
    { 'key' => 'pident',  'title'=> '%ID',                  'align' => 'left',  'sort' => 'numeric_hidden', 'help' => $glossary->{'%ID (BLAST Results)'}                        }
  ) ];
}

sub table_row {
  ## Returns one row per BLAST result to be added to the results table
  my ($self, $job, $result) = @_;

  my $result_id     = $result->result_id;
  my $result_row    = $result->result_data->raw;
  my $url_param     = $self->object->create_url_param({'result_id' => $result_id});
  my $urls          = $self->get_result_links($job, $result);

  $result_row->{'options'} = {'class' => "hsp_$result_id"};

  # orientation columns
  $result_row->{$_} = $result_row->{$_} == 1 ? 'Forward' : 'Reverse' for grep m/ori$/, keys %$result_row;

  # columns with links
  $result_row->{'gid'}    = $result_row->{'tid'} = qq($urls->{'location'}&nbsp;$urls->{'genomic_sequence'});
  $result_row->{'tid'}    = $urls->{'target'} unless $job->job_data->{'source'} =~ /latestgp/i;
  $result_row->{'gene'}   = $urls->{'gene'};
  $result_row->{'len'}    = sprintf('<span>%s</span>&nbsp;%s', $result_row->{'len'}, $urls->{'query_sequence'});
  $result_row->{'pident'} = sprintf('<span>%s</span>&nbsp;%s', $result_row->{'pident'}, $urls->{'alignment'});

  return $result_row;
}

sub table_options {
  ## Returns options for rendering the results table
  ## @param Job object
  ## @return Hashref of table options as expected by new_table method
  my ($self, $job) = @_;
  return {
    'id'          => sprintf('blast_results%s', $job->job_data->{'source'} =~ /latestgp/i ? '_1' : '_2'), # keep different session record for DataTable when saving sorting, hidden cols etc
    'data_table'  => 1,
    'sorting'     => ['score desc']
  };
}

sub get_result_links {
  ## Gets the links for all required table columns
  my ($self, $job, $result) = @_;

  my $hit   = $result->result_data;
  my $hub   = $self->hub;
  my $urls  = $self->object->get_result_urls($job, $result);

  return {
    'gene'              => join(', ', map { sprintf '<a href="%2$s">%1$s</a>', delete $_->{'label'}, $hub->url($_) } @{$urls->{'gene'}}) || '',
    'target'            => $urls->{'target'} ? sprintf('<a href="%s">%s</a>', $hub->url($urls->{'target'}),  $hit->{'v_tid'} ?  $hit->{'v_tid'} : $hit->{'tid'}) : '',
    'location'          => sprintf('<a href="%s" class="_ht" title="Region in Detail">%s:%s-%s</a>', $hub->url($urls->{'location'}), $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'}),
    'genomic_sequence'  => sprintf('<a href="%s" class="small _ht" title="View Genomic Sequence">[Sequence]</a>', $hub->url($urls->{'genomic_sequence'})),
    'query_sequence'    => sprintf('<a href="%s" class="small _ht" title="View Query Sequence">[Sequence]</a>', $hub->url($urls->{'query_sequence'})),
    'alignment'         => sprintf('<a href="%s" class="small _ht" title="View Alignment">[Alignment]</a>', $hub->url($urls->{'alignment'}))
  };
}

1;
