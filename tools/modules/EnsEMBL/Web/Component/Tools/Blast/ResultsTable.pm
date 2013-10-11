package EnsEMBL::Web::Component::Tools::Blast::ResultsTable;

### Component to display a table for all the results of a single blast job

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools::Blast);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $job       = $object->get_requested_job({'with_all_results' => 1});
  my $html      = '';

  if ($job && $job->status eq 'done' && @{$job->result}) {

    my $results     = $job->result;
    my $job_data    = $job->job_data;
    my $source      = $job_data->{'source'};
    my $table       = $self->new_table($source =~/latestgp/i
      ? [
          { 'key' => 'links',   'title'=> 'Links',          'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'qid',     'title'=> 'Query name',     'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'qstart',  'title'=> 'Query start',    'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'qend',    'title'=> 'Query end',      'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'qori',    'title'=> 'Query Ori',      'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'tid',     'title'=> 'Subject name',   'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'tori',    'title'=> 'Subject Ori',    'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'score',   'title'=> 'Score',          'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'evalue',  'title'=> 'E-val',          'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'pident',  'title'=> '%ID',            'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'len',     'title'=> 'Length',         'align' => 'left',  'sort' => 'numeric' },
        ]
      : [
          { 'key' => 'links',   'title'=> 'Links',          'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'qid',     'title'=> 'Query name',     'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'qstart',  'title'=> 'Query start',    'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'qend',    'title'=> 'Query end',      'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'qori',    'title'=> 'Query Ori',      'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'tid',     'title'=> 'Subject name',   'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'tstart',  'title'=> 'Subject start',  'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'tend',    'title'=> 'Subject end',    'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'tori',    'title'=> 'Subject Ori',    'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'gid',     'title'=> 'Chr name',       'align' => 'left',  'sort' => 'string'  },
          { 'key' => 'gori',    'title'=> 'Chr Ori',        'align' => 'left',  'sort' => 'none'    },
          { 'key' => 'score',   'title'=> 'Score',          'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'evalue',  'title'=> 'E-val',          'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'pident',  'title'=> '%ID',            'align' => 'left',  'sort' => 'numeric' },
          { 'key' => 'len',     'title'=> 'Length',         'align' => 'left',  'sort' => 'numeric' },
        ],
      [], {'data_table' => 1, 'exportable' => 0, 'sorting' => ['score desc']}
    );

    # Data for table rows
    for (@$results) {
      my $result_id     = $_->result_id;
      my $result_data   = $_->result_data;
      my $url_param     = $object->create_url_param({'result_id' => $result_id});
      my $location_link = $self->location_link($url_param, $job_data, $result_data);

      $result_data->{'links'}     = $self->all_links($url_param, $job_data, $result_data);
      $result_data->{'options'}   = {'class' => "hsp_$result_id"};

      if ($source =~ /latestgp/i) {
        $result_data->{'tid'} = $location_link;
      } else {
        $result_data->{'gid'} = $location_link;
        $result_data->{'tid'} = $self->subject_link($url_param, $job_data, $result_data);
      }
      $table->add_row($result_data);
    }

    $html .= sprintf '<h3><a rel="_blast_results_table" class="toggle set_cookie open" href="#">Results table</a></h3>
      <div class="_blast_results_table toggleable">%s</div>', $table->render;
  }

  return $html;
}

sub subject_link {
  ## Gets the link for the subject column
  ## @param URL param value for 'tl'
  ## @param Job object's job_data column value
  ## @param Result object's result_data column value
  my ($self, $url_param, $job_data, $result_data) = @_;

  my $source  = $job_data->{'source'};
  my $param   = $source =~/abinitio/i ? 'pt' : $source eq 'PEP_ALL' ? 'p' : 't';

  return sprintf '<a href="%s">%s</a>', $self->hub->url({
    'species' => $job_data->{'species'},
    'type'    => 'Transcript',
    'action'  => $source =~/cdna|ncrna/i ? 'Summary' : 'ProteinSummary',
    $param    => $result_data->{'tid'},
    'tl'      => $url_param
  }), $result_data->{'tid'};
}

sub all_links {
  ## Gets the links to be displayed in the links column
  ## @param URL param value for 'tl'
  ## @param Job object's job_data column value
  ## @param Result object's result_data column value
  my ($self, $url_param, $job_data, $result_data) = @_;

  my $hub         = $self->hub;
  my $species     = $job_data->{'species'};
  my $blast_prog  = $job_data->{'program'};

  return join(' ',

    # Alignment link
    sprintf('<a href="%s" class="_ht" title="Alignment">[A]</a>', $hub->url({
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => $job_data->{'db_type'} eq 'peptide' || $job_data->{'query_type'} eq 'peptide' ? 'ProteinAlignment' : 'Alignment',
      'tl'        => $url_param
    })),

    # Query sequence link
    sprintf('<a href="%s" class="_ht" title="Query Sequence">[S]</a>', $hub->url({
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => 'QuerySeq',
      'tl'        => $url_param
    })),

    # Genomic sequence link
    sprintf('<a href="%s" class="_ht" title="Genomic Sequence">[G]</a>', $hub->url({
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => 'GenomicSeq',
      'tl'        => $url_param
    }))
  );
}

sub location_link {
  ## Gets a link to the location view page for the given result
  ## @param URL param value for 'tl'
  ## @param Job object's job_data column value
  ## @param Result object's result_data column value
  my ($self, $url_param, $job_data, $result_data) = @_;

  my $region  = sprintf('%s:%s-%s', $result_data->{'gid'}, $result_data->{'gstart'}, $result_data->{'gend'});
  my $url     = $self->hub->url({
    'species'           => $job_data->{'species'},
    'type'              => 'Location',
    'action'            => 'View',
    'r'                 => $region,
    'contigviewbottom'  => [qw(blast_hit=normal blast_hit_btop=normal)],
    'tl'                => $url_param
  });

  return qq(<a href="$url" class="_ht" title="Region in Detail">$region</a>);
}

1;
