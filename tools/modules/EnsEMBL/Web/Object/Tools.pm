package EnsEMBL::Web::Object::Tools;

use strict;
use warnings;
no warnings "uninitialized";

use EnsEMBL::Web::SpeciesDefs;
use Storable qw(nfreeze thaw);
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Bio::Root::IO;
use Data::Dumper;

use base qw(EnsEMBL::Web::Object);

sub caption { return 'Tools'; }
sub short_caption { return "Tools"; }

sub long_caption {
  my $self = shift;
  return 'Tools' if $self->action ne 'BlastResults';

  my $caption =  sprintf ('<h1>Results for %s: <span class="small"><a href ="%s">[Change ticket]</a></span></h1>',
    $self->hub->param('tk'),
    $self->hub->url({ action => 'Summary', tk => undef})
  );
}

sub session_id    { my $self = shift; return $self->hub->session->session_id || undef; }
sub user_id       { my $self = shift; return $self->hub->user ? $self->hub->user->user_id : undef; }
sub species_defs  { return new EnsEMBL::Web::SpeciesDefs; }

sub ticket { my $self = shift; return $self->Obj->{'_ticket'} || undef;}

sub hive_adaptor {
  my $self = shift;
   
  my $adaptor = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new(
    -user   => $self->species_defs->DATABASE_WRITE_USER,
    -pass   => $self->species_defs->DATABASE_WRITE_PASS,
    -host   => $self->species_defs->multidb->{'DATABASE_WEB_HIVE'}{'HOST'},
    -port   => $self->species_defs->multidb->{'DATABASE_WEB_HIVE'}{'PORT'},
    -dbname => $self->species_defs->multidb->{'DATABASE_WEB_HIVE'}{'NAME'},     
  );

  return $adaptor;
}

sub create_ticket {
  my $self = shift;

  my $now = $self->get_time_now;
  my $owner_id = $self->user_id ? 'user_'. $self->user_id : 'session_' . $self->session_id;
  my $name = $self->get_unique_ticket_name; 
  my $job_id = $self->rose_manager('Job')->get_job_id_by_name($self->{'_analysis'});
  my $description = $self->{'_description'};
  my $site_type = $self->species_defs->ENSEMBL_SITETYPE;

  # First create and save ticket
  my $ticket = $self->rose_manager('Ticket')->create_empty_object;
  $ticket->ticket_name($name);
  $ticket->owner_id($owner_id);
  $ticket->job_type_id($job_id);
  $ticket->created_at($now);
  $ticket->modified_at($now);
  $ticket->status('Queued');
  $ticket->site_type($site_type);
  $ticket->ticket_desc($description);

  # Then create analysis object - this contains params needed to run job
  # create serialised and gzipped version of the analysis object to store in ticket DB.
  my $serialised_analysis = $self->serialise;
  $ticket->analysis(object => $$serialised_analysis);
 
  # Finally save objects
  $ticket->save(cascade => 1);

  return $ticket; 
}

sub submit_job {
  my ($self, $ticket)  = @_;

  my $analysis_adaptor  = $self->rose_manager('Analysis');
  my $serialised_object = $analysis_adaptor->retrieve_analysis_object($ticket->ticket_id); 
  my $analysis_object = $self->deserialise($serialised_object);
  $analysis_object->create_jobs($ticket);
  
  return;
}

sub display_status {
  my ($self, $job_status) = @_;
  
  my %status_lookup = (
    'SEMAPHORED'   => 'Pending',
    'READY'        => 'Pending', 
    'BLOCKED'      => 'Pending',
    'CLAIMED'      => 'Pending',
    'COMPILATION'  => 'Pending',
    'PRE_CLEANUP'  => 'Pending',
    'FETCH_INPUT'  => 'Pending',
    'RUN'          => 'Running',  
    'WRITE_OUTPUT' => 'Parsing',
    'POST_CLEANUP' => 'Parsing',
    'DONE'         => 'Completed',  
    'FAILED'       => 'Failed',
    'PASSED_ON'    => 'Failed',
  );
  return $status_lookup{$job_status};
}

sub fetch_current_tickets {
  my $self = shift;
  my (@user_tickets, @session_tickets, $all_tickets);

  if ($self->user_id) {
   @user_tickets = @{$self->rose_manager('Ticket')->fetch_all_tickets_by_user($self->user_id) || []};
  }

  @session_tickets = @{$self->rose_manager('Ticket')->fetch_all_tickets_by_session($self->session_id) || []};
  $all_tickets = [@user_tickets, @session_tickets];

  return $all_tickets;
}

sub fetch_ticket_by_name {
  my ($self, $ticket_name) = @_;
  return unless $ticket_name;

  my $ticket = shift @{$self->rose_manager('Ticket')->fetch_by_ticket_name($ticket_name)};

  if(!$ticket){$ticket = 'The requested ticket "'.$ticket_name.'" could not be found.'
    .' Please be aware that all tickets are deleted after 7 days unless you save'
    .' them to a user account.';
  }

  return $ticket;
}

sub check_submission_status {
  my ($self, $ticket) = @_;
  return $ticket->status unless ref $ticket->sub_job;

  # Set ticket status to be that of the sub job that has progressed the least    
  my %status_priority = (
    'Queued'   => 0,
    'Pending'   => 1,
    'Running'   => 2,
    'Parsing'   => 3,
    'Completed' => 4,
    'Failed'    => 5,
    'Deleted'   => 6,    
  );
 
  my $status;
  foreach my $job (@{$ticket->sub_job}){  
    my $display_status = $self->get_hive_job_status($job->sub_job_id);
    $status = $status_priority{$display_status} << $status_priority{$status} ? $display_status : $status; 
  } 

  # update status in ticket db
  my $now = $self->get_time_now;
  $ticket->status($status);
  $ticket->modified_at($now);
  $ticket->analysis->modified_at($now);
  foreach (@{$ticket->sub_job}){ $_->modified_at($now); } 
  $ticket->save(cascade => 1);

  return $status;
}


sub get_hive_job_status {
  my ($self, $hive_job_id) = @_;
  my $job_adaptor = $self->hive_adaptor->get_AnalysisJobAdaptor;
  my $job_status = $job_adaptor->fetch_by_dbID($hive_job_id)->status;

  return  $self->display_status($job_status);      
}

sub get_hive_job_message {
  my ($self, $hive_job_id) = @_;
  my $adaptor = $self->hive_adaptor->get_NakedTableAdaptor();
  $adaptor->table_name('job_message');
  my $job_message_record = $adaptor->fetch_by_job_id($hive_job_id);
  my ($job_message, $line) = $job_message_record->{'msg'} =~/(.*)at(.*)$/;

  return $job_message;
}

sub format_date {
  my ($self, $datetime) = @_;
  return unless $datetime;

  my @date = split(/-|T|:/, $datetime);
  $datetime = sprintf('%s/%s/%s, %s:%s', 
    $date[2],
    $date[1],
    $date[0],
    $date[3],
    $date[4]
  );
  return $datetime;
}

sub delete_ticket {
  my ($self, $ticket_id) = @_;
  my $ticket = shift @{$self->rose_manager('Ticket')->fetch_by_ticket_name($ticket_id)};
  return unless $ticket;

  # First clean up any results files 
  my $work_dir =  $self->species_defs->ENSEMBL_TMP_DIR_BLAST;
  my $file_directory = $work_dir ."/" . substr($ticket->ticket_name, 0, 6) ."/" . substr($ticket->ticket_name, 6);
  my $parent_directory = $work_dir ."/" . substr($ticket->ticket_name, 0, 6);

  if (-d $file_directory){
    foreach my $sub_job (@{$ticket->sub_job}){
      my $filename = $file_directory .'/'. $ticket->ticket_id . $sub_job->sub_job_id;
      my @exts = ('seq.fa', 'seq.fa.masked', 'seq.fa.tab', 'seq.fa.out', 'seq.fa.raw');
      foreach (@exts){
        my $file = $filename .'.'. $_; 
        if ( -s $file ){ 
          unlink($file);
        }
      }
    }      
  
    unless (scalar <$file_directory/*>){ # remove directory if empty
      rmdir($file_directory); 
    }
  }

  if (-d $parent_directory){
    unless (scalar <$parent_directory/*>){ # remove directory if empty
      rmdir($parent_directory);
    }
  }

  # Then remove data from ticket database 
  if (ref $ticket->analysis){ $ticket->analysis->delete; }
  if (ref $ticket->sub_job){ $ticket->sub_job([]); }
  if (ref $ticket->result){$ticket->result([]);} 
  $ticket->save;  
  $ticket->delete;

  return;
}

sub error_message {
  my ($self, $ticket) = @_;
  my $job_adaptor = $self->hive_adaptor->get_AnalysisJobAdaptor;
  #my $job_message_adaptor = $self->hive_adaptor->getJobMessageAdaptor;

  foreach my $job (@{$ticket->sub_job}){
  }
}

#--------------------------------------------------
sub serialise {
  my ($self, $object) = @_; 
  
  $object = $self unless $object;  

  delete $object->{data};
  my $serialised = nfreeze($object);
  my $serialised_gzip;
  gzip \$serialised => \$serialised_gzip, -LEVEL => 9 or die "gzip failed: $GzipError";

  return \$serialised_gzip;
}

sub deserialise {
  my ($self, $object) = @_; 
  my $gunzipped_and_frozen;

  gunzip \$object => \$gunzipped_and_frozen or die "gunzip failed: $GunzipError";
  my $analysis_object = thaw($gunzipped_and_frozen);
  $analysis_object->{data} = $self->__data();

  return $analysis_object;
}

sub retrieve_analysis_object {
  my $self = shift;
  my $ticket = $self->ticket;
  return undef unless $ticket;

  my $analysis_adaptor  = $self->rose_manager('Analysis');
  my $serialised_object = $analysis_adaptor->retrieve_analysis_object($ticket->ticket_id);
  return undef unless $serialised_object;

  my $analysis_object = $self->deserialise($serialised_object);
  return $analysis_object
}

sub generate_analysis_object {
  my ($self, $type) = @_;

  return $self->new_object($type, 
    {},
    $self->__data
  );
}

sub get_time_now {
  my $self = shift;
  my ($sec, $min, $hour, $day, $mon, $year) = localtime();
  my $now = (1900+$year).'-'.sprintf('%02d', $mon+1).'-'.sprintf('%02d', $day).' '
              .sprintf('%02d', $hour).':'.sprintf('%02d', $min).':'.sprintf('%02d', $sec);
  return $now;
}

sub get_unique_ticket_name {
  my $self = shift;
  my $unique;

  while (!$unique ){
   my $template = "BLA_XXXXXXXX";
   $template =~ s/X/['0'..'9','A'..'Z','a'..'z']->[int(rand 54)]/ge;  
   unless (scalar @{$self->rose_manager('Ticket')->fetch_by_ticket_name($template)} > 0) {
    $unique = $template;
   }
  }
    
  return $unique;
}

#--------------------- Blast result calls ? may not belong here!

sub get_blast_method {
  my $self  = shift;
  my $analysis_object = $self->retrieve_analysis_object;
  my $method = $analysis_object->{'_methods'};
  return $method;
}

sub get_hit_db_entry {
  my ($self, $result_id) = @_;
  my $result_adaptor  = $self->rose_manager('Result');
  my $result_entry = shift @{$result_adaptor->fetch_result_by_result_id($result_id)};
  return $result_entry;
}

sub get_job_division_data {
  my ($self, $result_entry) = @_;
  my $frozen_division = $result_entry->sub_job->job_division;
  my $job_division = $self->deserialise($frozen_division);
  return $job_division;
}

sub fetch_blast_hit_by_id {
  my ($self, $result_id) = @_;

  # retrieve hit
  my $result_entry = $self->get_hit_db_entry($result_id);
  my $frozen_hit = $result_entry->result;
  my $hit = $self->deserialise($frozen_hit);
  return $hit;
}

sub complete_query_sequence {
  my ($self, $hit) = @_;
  my $query_id = $hit->{'qid'};
  my $analysis_object = $self->retrieve_analysis_object;
  my $seq_object = $analysis_object->{'_seqs'}{$query_id};
  my $seq = $seq_object->seq();
  return $seq;
}

sub query_hit_sequence {
  my ($self, $hit)  = @_;
  my $seq = $self->complete_query_sequence($hit);
  my $offset = $hit->{'qstart'} -1;
  $seq = substr($seq, $offset, $hit->{'len'});
  return $seq;
}

sub get_hit_genomic_slice {
  my ($self, $hit, $species, $flank5, $flank3) = @_; 
  my $start = $hit->{'gstart'} < $hit->{'gend'} ? $hit->{'gstart'} : $hit->{'gend'};
  my $end = $hit->{'gstart'} > $hit->{'gend'} ? $hit->{'gstart'} : $hit->{'gend'};
  my $coords = $hit->{'gid'}.':'.$start.'-'.$end.':'.$hit->{'gori'}; 
  my $slice_adaptor = $self->hub->get_adaptor('get_SliceAdaptor', 'core', $species);
  my $slice = $slice_adaptor->fetch_by_toplevel_location($coords); 
  return $flank5 || $flank3 ? $slice->expand($flank5, $flank3) : $slice;
}

sub get_hit_species {
  my ($self, $result_id)  = @_;

  # retrieve hit
  my $result_entry = $self->get_hit_db_entry($result_id);
  my $frozen_hit = $result_entry->result;
  my $hit = $self->deserialise($frozen_hit);

  my $job_division = $self->get_job_division_data($result_entry);
  my $species = $job_division->{'species'};

  return $species;
}

sub get_ticket_hits_by_coords{
  my ($self, $coords, $ticket_id, $species) = @_;
 
  my $slice_adaptor = $self->database('core', $species)->get_SliceAdaptor;  
  my $slice = $slice_adaptor->fetch_by_toplevel_location($coords);

  return $self->get_all_hits_from_ticket_in_region($slice, $ticket_id);
}

sub get_all_hits_from_ticket_in_region {
  my ($self, $slice, $id) = @_;
  my $ticket_id = $id || $self->ticket->ticket_id;
  my @aligned_hits; 

  
  my $result_adaptor = $self->rose_manager('Result');
  my @result_objects = @{$result_adaptor->fetch_all_results_in_region($ticket_id, $slice)};
  foreach (@result_objects) { 
    my $frozen_gzipped_hit = $_->result; 
    my $hit = $self->deserialise($frozen_gzipped_hit);
    push @aligned_hits, [$_->result_id, $hit];
  }
  
  return \@aligned_hits;
}


sub map_btop_to_genomic_coords {
  my ($self, $hit, $result_id) = @_;

  return $hit->{'galn'} if $hit->{'galn'};

  my $result = $self->get_hit_db_entry($result_id); 

  my $btop = $hit->{'aln'};
  chomp $btop;
  my $genomic_btop;
  my $coords = $hit->{'g_coords'} || undef;

  #### temp for testing! ####
  $hit->{'db_type'} = 'cdna';

  my $target_object = $self->get_target_object($hit);
  my $mapping_type = $hit->{'db_type'} =~/pep/i ? 'pep2genomic' : 'cdna2genomic';


  my $gap_start = $coords->[0]->end;
  my $gap_count = scalar @$coords;
  my $processed_gaps = 0;

  # reverse btop string if necessary so always dealing with + strand genomic coords
  my $object_strand = $target_object->isa('Bio::EnsEMBL::Translation') ? $target_object->translation->start_Exon->strand :
                      $target_object->strand;

  my $rev_flag = $object_strand ne $hit->{'tori'} ? 1 : undef;
  $btop= scalar reverse ("$btop") if $rev_flag;

  # account for btop strings that do not start with a match;  
  $btop = '0'.$btop  if $btop !~/^\d+/ ;
 

  $btop =~s/(\d+)/:$1:/g;
  $btop =~s/^:|:$//g;
  my @btop_features = split (/:/, $btop);
  @btop_features = map { scalar reverse("$_")} @btop_features if $rev_flag; 
 
  my $genomic_start = $hit->{'gstart'};
  my $genomic_end   = $hit->{'gend'};
  my $genomic_offset = $genomic_start;
  my $target_offset  = $hit->{'tori'} == 1 ? $hit->{'tstart'} : $hit->{'tend'}; 

  while (scalar @btop_features > 0){
    my $num_matches = shift @btop_features;
    my $diff_string = shift @btop_features;
    next unless $diff_string;

    my $diff_length = (length $diff_string) / 2;
    my $temp = $diff_string;
    my @diffs = (split //, $temp);

    # Account for bases inserted in query relative to target    
    my $insert_in_query = 0;
    my $gap_in_query = 0;
    my $require_mapping;

    while (defined( my $query_base = shift @diffs)){
      my $target_base = shift @diffs;
      $insert_in_query++ if $target_base eq '-'; 
      $gap_in_query++ if $query_base eq '-';
      $require_mapping = 1 if $target_base ne '-';
    }  

    my ($difference_start, $difference_end);

    if ($hit->{'tori'} eq '-1') {
      $difference_end = $target_offset - $num_matches;
      $difference_start = $difference_end - $diff_length + $insert_in_query + 1;
      $target_offset = $difference_start -1;
    } else {
      $difference_start = $target_offset + $num_matches;
      $difference_end  = $difference_start + $diff_length - $insert_in_query -1;
      $target_offset = $difference_end +1;
    }
;
    my @mapped_coords = ( sort { $a->start <=> $b->start }
                          grep { ! $_->isa('Bio::EnsEMBL::Mapper::Gap') }
                          $target_object->$mapping_type($difference_start, $difference_end, $hit->{'tori'} )
                        );

    my $mapped_start = $mapped_coords[0]->start;
    my $mapped_end   = $mapped_coords[-1]->end;  
;
    # Check that mapping occurs before the next gap
    if ($mapped_start < $gap_start && $mapped_end <= $gap_start){ 
      $genomic_btop .= $num_matches;
      $genomic_btop .= $diff_string;
      $genomic_offset = $mapped_end +1;
    } elsif ($mapped_start > $gap_start){

      # process any gaps in mapped genomic coords first
      while ($mapped_start > $gap_start){
        my $matches_before_gap = $gap_start - $genomic_offset + 1;
        my $gap_end = $coords->[$processed_gaps + 1]->start -1;
        my $gap_length = ($gap_end - $gap_start);
        my $gap_string = '-N'x $gap_length;
        $genomic_offset = $gap_end + 1;
        $genomic_btop .= $matches_before_gap;
        $genomic_btop .= $gap_string;

        $processed_gaps++;
        $gap_start = $coords->[$processed_gaps]->end || $genomic_end;
      }

      # Add difference info
      my $matches_after_gap = $mapped_start - $genomic_offset;
      $genomic_btop .= $matches_after_gap;     
      $genomic_btop .= $diff_string;
      $genomic_offset = $mapped_end +1 unless $object_strand eq '-1';
    } elsif( $mapped_start < $gap_start && $mapped_end > $gap_start) { 
      # Difference in btop string spans a gap in the genomic coords
  
      my $diff_matches_before_gap = $gap_start - $mapped_start;
      my $diff_index = ( $diff_matches_before_gap * 2 ) -1;
      my $diff_before_gap = join('', @diffs[0..$diff_index]);
      $diff_index++;      

      $genomic_btop .= $num_matches;
      $genomic_btop .= $diff_before_gap;
 

      while ($mapped_end > $gap_start) {
        my $gap_end = $coords->[$processed_gaps + 1]->start -1;
        my $gap_length = ($gap_end - $gap_start);
        my $gap_string = '-N'x $gap_length;
        $processed_gaps++;
        $gap_start = $coords->[$processed_gaps]->end || $genomic_end;
 
        my $match_number = $gap_start - $gap_end;              
        my $diff_end = $diff_index + ( $match_number * 2 ) -1;

        my $diff_after_gap = join('', @diffs[$diff_index..$diff_end]);
        $genomic_btop .= $gap_string;
        $genomic_btop .= $diff_after_gap;    
        $diff_index = $diff_end +1;
      } 

      my $diff_after_gap = join('', @diffs[$diff_index..-1]);
      $genomic_btop .= $diff_after_gap;

      $genomic_offset = $mapped_end +1;
    } else {
      warn ">> mapping case not caught!  $mapped_start $mapped_end $gap_start";
    }
  }


  # Add in any gaps from mapping to genomic coords that occur after last btop feature    
  while ($gap_count > $processed_gaps +1){
    my $num_matches = $gap_start - $genomic_offset + 1;
    my $gap_end = $coords->[$processed_gaps + 1]->start -1;
    my $gap_length = ($gap_end - $gap_start);
    my $gap_string = '-N'x $gap_length;

    $genomic_btop .= $num_matches;
    $genomic_btop .= $gap_string;

    $genomic_offset = $gap_end +1;
    $gap_start = $coords->[$processed_gaps + 1]->end;
    $processed_gaps++;
  }

 
  my $btop_end =  $genomic_end - $genomic_offset +1;
  $genomic_btop .= $btop_end;

  # Write back to database so we only have to do this once
  $hit->{'galn'} = $genomic_btop;
  delete $hit->{'data'};

  my $serialised_hit = nfreeze($hit);
  my $serialised_gzip;
  gzip \$serialised_hit => \$serialised_gzip, -LEVEL => 9 or die "gzip failed: $GzipError";

  $result->result($serialised_hit);
  $result->save; 

  return $genomic_btop;
}

sub get_target_object {
  my ($self, $hit ) = @_;
  my $id = $hit->{'tid'};
  my $species = $hit->{'species'};
  my $database_type = $hit->{'db_type'};

  my $feature_type = $database_type =~ /abinitio/i ? 'PredictionTranscript' :
                    $database_type =~ /cdna/i ? 'Transcript' : 'Translation';
 
  my $adaptor = $self->hub->get_adaptor('get_' . $feature_type .'Adaptor', 'core', $species); 
  my $target = $adaptor->fetch_by_stable_id($id);
  
  return $target;
}

#------------------------------------------------

sub valid_analysis { # check that the analysis param matches an analysis type we have
}
1;
