package EnsEMBL::Web::Component::Tools::BlastResults;

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

  return $self->select_ticket('Blast') unless $hub->param('tk');
  
  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  unless ( ref($ticket) ){ 
    my $error = $self->_error('Ticket not found', $ticket, '100%');
    return $self->select_ticket('Blast', $error);
  }

  ## We have a ticket!
  my $html;
  my $name = $ticket->ticket_name;

  $html .=  sprintf ('<h2>Results for %s: <span class="small"><a href ="%s">[Change ticket]</a></span></h2>', 
    $name,  
    $self->hub->url({ tk => undef})
  );


  my $status = $ticket->status;
    
  # Work out what type of database was searched against - needed to generate links
  my $serialised_analysis = $ticket->analysis->object;
  my $analysis_object = $object->deserialise($serialised_analysis);
  my @temp = values %{$analysis_object->{'_database'}};
  my $db_type = $temp[0]->{'type'};
  

  my @hive_jobs = @{$ticket->sub_job};
  my @rows;
    

  foreach my $hive_job (@hive_jobs ){
    if ($status eq 'Completed'){
      my $sub_job_id = $hive_job->sub_job_id;
      my $ticket_id = $ticket->ticket_id;
      my $filename =  $ticket->ticket_id . $sub_job_id . '.seq.fa.raw';
      my $raw_output_link = $self->get_download_link($name, 'raw', $filename); 

      my @results = @{$object->rose_manager('Result')->fetch_results_by_ticket_sub_job($ticket_id, $sub_job_id)};

      if ( scalar @results < 1) {
        my $text = "<p>If you believe that there should be a match to your query sequence(s) please adjust the configuration parameters you selected and resubmit the search.</p>";
        $html .= $self->_error('No results found', $text, '100%' );
      } else {
        $html .= sprintf '<a href="%s" rel="external">View raw results file</a>', $raw_output_link;

        foreach (@results) {
          my $gzipped_serialsed_res = $_->{'result'};
          my $result = $object->deserialise($gzipped_serialsed_res);
          my $links = $self->generate_links($_, $result);
          $result->{'links'} = $links;
          $result->{'options'} = {'class' => 'hsp_' . $_->{'result_id'}};
          $result->{'tid'} = $self->subject_link($result->{'tid'}, $db_type, $result->{'species'});
          push (@rows, $result);  
        }
      }
    }
  }

  return $html unless scalar @rows > 0;

  $html .= $self->results_table($ticket, \@rows, $db_type);

  return $html;
}

sub subject_link {
  my ($self, $id, $db_type, $species) = @_;
  my ($url, $action, $param);
  my $ticket_name = $self->hub->param('tk');

  return $id if $db_type =~/latest/i;

  $action = $db_type =~/cdna|ncrna/i ? 'Summary' : 'ProteinSummary';
  $param = $db_type =~/abinitio/i ? 'pt' : $db_type eq 'PEP_ALL' ? 'p' : 't';

    $url = $self->hub->url({
      species => $species,
      type    => 'Transcript',
      action  => $action,
      $param  => $id,
      tk      => $ticket_name
    });


  my $link = $url =~/\w/ ? "<a href=$url>$id</a>" : $id;
  return $link;
}

sub generate_links {
  my ($self, $result_entry, $result) = @_;
  my $links = $self->alignment_link($result_entry, $result);
  $links .= ' ' . $self->query_sequence_link($result_entry, $result);
  $links .= ' ' . $self->genomic_sequence_link($result_entry, $result);
  $links .= ' ' .$self->location_link($result_entry, $result);  
  return $links;
}

sub alignment_link {
  my ($self, $result_entry, $result) = @_;
  my $ticket_name   = $self->hub->param('tk');
  my $hit           = $result_entry->sub_job_id;
  my $res           = $result_entry->result_id;
  my $species       = $result->{'species'};
  my $blast_method  = $self->object->get_blast_method;
  my $action        = $blast_method =~/[blastx]|[blastp]/i ? 'BlastAlignmentProtein' : 'BlastAlignment';
 
  my $url = $self->hub->url({
    species => $species,
    type    => 'Tools',
    action  => $action,
    tk      => $ticket_name,
    hit     => $hit,
    res     => $res
  });

  my $link = "<a href = $url title = 'Alignment' >[A]</a>";
  return $link;
}

sub query_sequence_link {
  my ($self, $result_entry, $result) = @_;
  my $ticket_name = $self->hub->param('tk');
  my $hit         = $result_entry->sub_job_id;
  my $res         = $result_entry->result_id;
  my $species     = $result->{'species'};


  my $url = $self->hub->url({
    species => $species, 
    type    => 'Tools',
    action  => 'BlastQuerySeq',
    tk      => $ticket_name,
    hit     => $hit,
    res     => $res
  });

  my $link = "<a href = $url title = 'Query Sequence' >[S]</a>";
  return $link;
}

sub genomic_sequence_link {
  my ($self, $result_entry, $result) = @_;
  my $ticket_name = $self->hub->param('tk');
  my $hit         = $result_entry->sub_job_id;
  my $res         = $result_entry->result_id;
  my $species     = $result->{'species'};
 
  my $url = $self->hub->url({
    species => $species,
    type    => 'Tools',
    action  => 'BlastGenomicSeq',
    tk      => $ticket_name,
    hit     => $hit,
    res     => $res
  });

  my $link = "<a href = $url title = 'Genomic Sequence' >[G]</a>";
  return $link;
}

sub location_link {
  my ($self, $result_entry, $result) = @_;
  my $ticket_name = $self->hub->param('tk'); 
  my $ticket      = $result_entry->ticket_id;
  my $hit         = $result_entry->sub_job_id;
  my $seq_region  = $result->{'gid'};
  my $start       = $result->{'gstart'};
  my $end         = $result->{'gend'};
  my $hsp         = $result_entry->result_id; 
  my $species     = $result->{'species'};

  my $url = $self->hub->url({
      species =>  $species,
      type    => 'Location',
      action  => 'View',
      r       => $seq_region . ':' . $start . '-' . $end,
      tk      => $ticket_name,
      ticket  => $ticket,
      hit     => $hit,
      h       => $hsp, 
      contigviewbottom => 'blast_hit=normal;contigviewbottom=blast_hit_btop=normal'
    });

  my $link = "<a href=$url title ='Region in Detail'>[R]</a>";
  return $link;
}

sub results_table {
  my ($self, $ticket, $results, $db_type) = @_;
  my $table = $self->new_table([], [], {data_table => 1, exportable => 0, sorting => ['score desc'], id => 'blast_res'});
  if ($db_type =~/latestgp/i){
    $table->add_columns(
      { 'key' => 'links',   'title'=> 'Links',          'align' => 'left', sort => 'none'   },
      { 'key' => 'qid',     'title'=> 'Query name',     'align' => 'left', sort => 'string' },
      { 'key' => 'qstart',  'title'=> 'Query start',    'align' => 'left', sort => 'none'   },
      { 'key' => 'qend',    'title'=> 'Query end',      'align' => 'left', sort => 'none'   },
      { 'key' => 'qori',    'title'=> 'Query Ori',      'align' => 'left', sort => 'none'   },
      { 'key' => 'tid',     'title'=> 'Subject name',   'align' => 'left', sort => 'string' },
      { 'key' => 'tstart',  'title'=> 'Subject start',  'align' => 'left', sort => 'none'   },
      { 'key' => 'tend',    'title'=> 'Subject end',    'align' => 'left', sort => 'none'   },
      { 'key' => 'tori',    'title'=> 'Subject Ori',    'align' => 'left', sort => 'none'   },
      { 'key' => 'score',   'title'=> 'Score',          'align' => 'left', sort => 'numeric' },
      { 'key' => 'evalue',  'title'=> 'E-val',          'align' => 'left', sort => 'numeric' },
      { 'key' => 'pident',  'title'=> '%ID',            'align' => 'left', sort => 'numeric' },
      { 'key' => 'len',     'title'=> 'Length',         'align' => 'left', sort => 'numeric' },
    );
  } else { 
    $table->add_columns(
      { 'key' => 'links',   'title'=> 'Links',          'align' => 'left', sort => 'none'   },
      { 'key' => 'qid',     'title'=> 'Query name',     'align' => 'left', sort => 'string' },
      { 'key' => 'qstart',  'title'=> 'Query start',    'align' => 'left', sort => 'none'   },
      { 'key' => 'qend',    'title'=> 'Query end',      'align' => 'left', sort => 'none'   },
      { 'key' => 'qori',    'title'=> 'Query Ori',      'align' => 'left', sort => 'none'   },
      { 'key' => 'tid',     'title'=> 'Subject name',   'align' => 'left', sort => 'string' },
      { 'key' => 'tstart',  'title'=> 'Subject start',  'align' => 'left', sort => 'none'   },
      { 'key' => 'tend',    'title'=> 'Subject end',    'align' => 'left', sort => 'none'   },
      { 'key' => 'tori',    'title'=> 'Subject Ori',    'align' => 'left', sort => 'none'   },
      { 'key' => 'gid',     'title'=> 'Chr name',       'align' => 'left', sort => 'string' },
      { 'key' => 'gstart',  'title'=> 'Chr start',      'align' => 'left', sort => 'none'   },
      { 'key' => 'gend',    'title'=> 'Chr end',        'align' => 'left', sort => 'none'   },
      { 'key' => 'gori',    'title'=> 'Chr Ori',        'align' => 'left', sort => 'none'   },
      { 'key' => 'score',   'title'=> 'Score',          'align' => 'left', sort => 'numeric' },  
      { 'key' => 'evalue',  'title'=> 'E-val',          'align' => 'left', sort => 'numeric' },
      { 'key' => 'pident',  'title'=> '%ID',            'align' => 'left', sort => 'numeric' },
      { 'key' => 'len',     'title'=> 'Length',         'align' => 'left', sort => 'numeric' },
    );
  }

  $table->add_rows(@$results);
  return $table->render;
}

1;
