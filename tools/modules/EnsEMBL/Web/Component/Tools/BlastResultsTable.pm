package EnsEMBL::Web::Component::Tools::BlastResultsTable;

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
  my $html;

  return unless $hub->param('tk');

  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  return unless ref($ticket);

  # Work out what type of database was searched against - needed to generate links
  my $serialised_analysis = $ticket->analysis->object;
  my $analysis_object = $object->deserialise($serialised_analysis);
  my @temp = values %{$analysis_object->{'_database'}};
  my $db_type = $temp[0]->{'type'};
  my @hive_jobs = @{$ticket->sub_job};
  my $status = $ticket->status;
  my $name = $ticket->ticket_name;
  my @rows;
 
  foreach my $hive_job (@hive_jobs ){
    if ($status eq 'Completed'){
      my $sub_job_id = $hive_job->sub_job_id;
      my $ticket_id = $ticket->ticket_id;
      my $filename =  $ticket->ticket_id . $sub_job_id . '.seq.fa.raw';
      my $raw_output_link = $self->get_download_link($name, 'raw', $filename);
      my $ticket_name = $self->hub->param('tk');


      my @results = @{$object->rose_manager('Result')->fetch_results_by_ticket_sub_job($ticket_id, $sub_job_id)};

      foreach (@results) {
        my $gzipped_serialsed_res = $_->{'result'};
        my $result = $object->deserialise($gzipped_serialsed_res);
        my $res = $_->result_id;

        my $links = $self->generate_links($_, $result, $ticket_name, $sub_job_id, $res);
        $result->{'links'} = $links;
        $result->{'options'} = {'class' => 'hsp_' . $_->{'result_id'}};
        $result->{'tid'} = $self->subject_link($result->{'tid'}, $db_type, $result->{'species'});

        my $region_link = $self->location_link($ticket_name, $sub_job_id, $res, $_, $result, $result->{'species'});
        my $region = $result->{'gid'}  .':'. $result->{'gstart'} .'-'. $result->{'gend'};
        $region_link =~s/\[R\]/$region/;
        if ($db_type =~/latestgp/i){
          $result->{'tid'} = $region_link;
        } else { 
          $result->{'gid'} = $region_link;  
        }

        push (@rows, $result);
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
  my ($self, $result_entry, $result, $ticket_name, $hit, $res) = @_;
  my $species = $result->{'species'};
  my $blast_method  = $self->object->get_blast_method;

  my $links = $self->alignment_link($ticket_name, $hit, $res,  $species, $blast_method);
  $links .= ' ' . $self->query_sequence_link($ticket_name, $hit, $res);
  $links .= ' ' . $self->genomic_sequence_link($ticket_name, $hit, $res, $species);
  $links .= ' ' .$self->location_link($ticket_name, $hit, $res, $result_entry, $result, $species);
  return $links;
}

sub alignment_link {
  my ($self, $ticket_name, $hit, $res, $species, $blast_method) = @_;
  my $action        = $blast_method =~/^(blastn)|blat/ ? 'BlastAlignment' : 'BlastAlignmentProtein';

  my $url = $self->hub->url({
    species => $species,
    type    => 'Tools',
    action  => $action,
    tk      => $ticket_name,
    hit     => $hit,
    res     => $res,
    method  => $blast_method,
  });

  my $link = "<a href = $url title = 'Alignment' >[A]</a>";
  return $link;
}

sub query_sequence_link {
  my ($self, $ticket_name, $hit, $res, $species) = @_;

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
  my ($self, $ticket_name, $hit, $res, $species) = @_;

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
  my ($self, $ticket_name, $hit, $res, $result_entry, $result, $species) = @_;
  my $ticket      = $result_entry->ticket_id;
  my $seq_region  = $result->{'gid'};
  my $start       = $result->{'gstart'};
  my $end         = $result->{'gend'};
  my $hsp         = $result_entry->result_id;

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

