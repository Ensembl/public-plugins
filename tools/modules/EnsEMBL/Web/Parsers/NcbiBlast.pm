package EnsEMBL::Web::Parsers::NcbiBlast;

use strict;
use warnings;

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::DBConnection;
use Bio::EnsEMBL::Utils::IO qw/iterate_file/;
use Storable qw(nfreeze);
use IO::Compress::Gzip qw(gzip $GzipError);

sub new {
  my ($class, $runnable) = @_;
  return bless ( { 
    results_file      => $runnable->results_file,
    reformat_program  => $runnable->program('blast_formatter'),
    species           => $runnable->param('species'),
    database_type     => $runnable->param('database_type'),
    dba               => Bio::EnsEMBL::DBSQL::DBAdaptor->new(%{$runnable->param('dba')}),
    ticket_dbc        => Bio::EnsEMBL::DBSQL::DBConnection->new(%{$runnable->param('ticket_dbc')}),
    ticket_id         => $runnable->param('ticket'),
    sub_job_id        => $runnable->input_job->dbID,     
  }, ref ($class) || $class);
}

sub results_file {
  my ($self) = @_;
  return $self->{results_file};
}

sub reformat_program {
  my ($self) = @_;
  return $self->{reformat_program};
}

sub species {
  my ($self) = @_;
  return $self->{species};
}

sub database_type {
  my ($self) = @_;
  return $self->{database_type};
}

sub dba {
  my ($self) = @_;
  return $self->{dba};
}

sub ticket_dbc {
  my ($self) = @_;
  return $self->{ticket_dbc};
}

sub ticket_id {
  my ($self) = @_;
  return $self->{ticket_id};
}

sub sub_job_id {
  my ($self) = @_;
  return $self->{sub_job_id};
}

sub parse {
  my ($self) = @_;
  my $results_tab = $self->reformat;
  my $results = $self->parse_tab($results_tab);
  $self->write_results($results);
  
  $self->dba->dbc->disconnect_if_idle;
  $self->ticket_dbc->disconnect_if_idle;
}

sub parse_tab {
  my ($self, $results_tab) = @_; 
  my @results;
  my $now = $self->get_time_now;
  my $ticket_id = $self->ticket_id;
  my $sub_job_id = $self->sub_job_id;


  iterate_file($results_tab, sub {
    my ($line) = @_;

    my @hit_data = split (/\t/, $line);
    my $q_ori = $hit_data[1] < $hit_data[2] ? 1 : -1;
    my $t_ori = $hit_data[4] < $hit_data[5] ? 1 : -1;

    my $tstart = $hit_data[4] < $hit_data[5] ? $hit_data[4] : $hit_data[5];
    my $tend = $hit_data[4] < $hit_data[5] ? $hit_data[5] : $hit_data[4];


    my $hit = {
      qid     => $hit_data[0],
      qstart  => $hit_data[1],
      qend    => $hit_data[2],
      qori    => $q_ori,
      qframe  => $hit_data[11],
      tid     => $hit_data[3],
      tstart  => $tstart,
      tend    => $tend,
      tori    => $t_ori,
      tframe  => $hit_data[12],
      score   => $hit_data[6],
      evalue  => $hit_data[7],
      pident  => $hit_data[8],
      len     => $hit_data[9],
      aln     => $hit_data[10],
    };

    my $hit_mapped_to_genomic = $self->map_to_genome($hit);
    my $chr_name = $hit_mapped_to_genomic->{'gid'};
    my $chr_start   = $hit_mapped_to_genomic->{'gstart'};
    my $chr_end   = $hit_mapped_to_genomic->{'gend'};
    my $serialised = nfreeze($hit_mapped_to_genomic);
    my $serialised_gzip;
    gzip \$serialised => \$serialised_gzip, -LEVEL => 9 or die "gzip failed: $GzipError";

    push (@results, {ticket_id  => $ticket_id,
                    sub_job_id => $sub_job_id,
                    result     => $serialised,
                    created_at => $now,
                    chr_name   => $chr_name,
                    chr_start  => $chr_start,
                    chr_end    => $chr_end
    });
  });

  return \@results;
}

sub map_to_genome {
  my ($self, $hit) = @_;
  my $database_type = $self->database_type;
  my $species = $self->species;
  my ($g_id, $g_start, $g_end, $g_ori, $g_coords, $g_aln);

  if ($database_type =~/LATESTGP/){
    $g_id = $hit->{'tid'};
    $g_start = $hit->{'tstart'};
    $g_end  = $hit->{'tend'};
    $g_ori  = $hit->{'tori'};
    $g_aln  = $hit->{'aln'}
  } else {
    my $feature_type = $database_type =~ /abinitio/i ? 'PredictionTranscript' :
                       $database_type =~ /cdna/i ? 'Transcript' : 'Translation';
    my $mapper = $database_type =~ /pep/i ? 'pep2genomic' : 'cdna2genomic';

    my $dba = $self->dba;
    my $adaptor = $dba->get_adaptor($feature_type);

    my $object = $adaptor->fetch_by_stable_id($hit->{'tid'});
    if ($object) { 
      if ($feature_type eq 'Translation'){ $object = $object->transcript; }
      my @coords = ( sort { $a->start <=> $b->start }
                   grep { ! $_->isa('Bio::EnsEMBL::Mapper::Gap') }
                   $object->$mapper($hit->{'tstart'}, $hit->{'tend'}, $hit->{'tori'})
                 );

      $g_id = $object->seq_region_name;
      $g_start = $coords[0]->start;
      $g_end = $coords[-1]->end;
      $g_ori = $object->strand eq $hit->{'tori'} ? $object->strand :
             $object->strand  eq '1' ? '1' : '-1';

      $g_coords = \@coords;
    } else {
      $g_id = 'Unmapped';
      $g_start  = 'N/A';
      $g_end = 'N/A';
      $g_ori = 'N/A'
    }
  }

  $hit->{'gid'} = $g_id;
  $hit->{'gstart'} = $g_start;
  $hit->{'gend'} = $g_end;
  $hit->{'gori'} = $g_ori;
  $hit->{'species'} = $species;
  $hit->{'db_type'} = $database_type;
  if ($g_coords){ $hit->{'g_coords'} = $g_coords; }

  return $hit;
}

sub reformat {
  my ($self) = @_;
  my $reformat_program = $self->reformat_program;
  my $results_file = $self->results_file;

  my $results_raw = $results_file;
  $results_raw =~s/out/raw/;
  my $raw_format_command = "$reformat_program -archive $results_file -out $results_raw";
  system $raw_format_command;

  my $results_tab = $results_file;
  $results_tab =~s/out/tab/;
  my $output_options = '"6 qseqid qstart qend sseqid sstart send bitscore evalue pident length btop qframe sframe"';
  my $parse_format_command = "$reformat_program -archive $results_file -out $results_tab -outfmt $output_options";
  system $parse_format_command;

  return $results_tab;
}

sub write_results {
  my ($self, $results) = @_;
  my $dbc = $self->ticket_dbc;
  $dbc->sql_helper->batch(
    -SQL => 'insert into result (ticket_id, sub_job_id, result, chr_name, chr_start, chr_end, created_at) values (?,?,?,?,?,?,?)',
    -CALLBACK => sub {
      my ($sth) = @_;
      foreach (@$results){
        $sth->execute( 
          $_->{'ticket_id'}, 
          $_->{'sub_job_id'}, 
          $_->{'result'}, 
          $_->{'chr_name'}, 
          $_->{'chr_start'}, 
          $_->{'chr_end'}, 
          $_->{'created_at'}, 
        );
      }
    }
  );
}

sub get_time_now {
  my $self = shift;
  my ($sec, $min, $hour, $day, $mon, $year) = localtime();
  my $now = (1900+$year).'-'.sprintf('%02d', $mon+1).'-'.sprintf('%02d', $day).' '
              .sprintf('%02d', $hour).':'.sprintf('%02d', $min).':'.sprintf('%02d', $sec);
  return $now;
}

1;
