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

package EnsEMBL::Web::Object::Blast;

## The aim is to create an object which can be updated to
## use a different queuing mechanism, without any need to
## change the user interface. Where possible, therefore,
## public methods should accept the same arguments and
## return the same values

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use EnsEMBL::Web::BlastConstants qw(CONFIGURATION_FIELDS);

use parent qw(EnsEMBL::Web::Object::Tools);

sub long_caption {
  ## For customised heading of the page
  my $self  = shift;
  my $hub   = $self->hub;
  if (($hub->function || '') eq 'Results') {
    if (my $job = $self->get_requested_job({'with_all_results' => 1})) {
      my $ticket      = $job->ticket;
      my $job_count   = $ticket->job_count;
      my $job_number  = $job->job_number;
      my $job_counter = $job_count == 1 && $job_number == 1 ? '' : " (Job $job_number/$job_count)";
      return sprintf 'Results for ticket %s%s', $ticket->ticket_name, $job_counter;
    }
    return sprintf '%s Results', $self->get_tool_caption;
  }
  return '';
}

sub get_current_tickets {
  ## @override
  ## Filters ticket on given ticket id instead of returning all tickets
  ## @return Arrayref of ticket objects
  my $self      = shift;
  my $hub       = $self->hub;
  my $function  = $hub->function || '';

  return $function eq 'refresh_tickets' && ($hub->referer->{'ENSEMBL_FUNCTION'} || '') eq 'Ticket' || $function eq 'Ticket'
    ? [ $self->get_requested_ticket(@_) ]
    : $self->SUPER::get_current_tickets(@_)
  ;
}

sub get_blast_form_options {
  ## Gets the list of options for dropdown fields in the blast input form
  my $self = shift;

  my $hub             = $self->hub;
  my $sd              = $self->species_defs;
  my @species         = $sd->valid_species;
  my $blast_types     = $sd->multi_val('ENSEMBL_BLAST_TYPES');              # hashref with keys as BLAT, NCBIBLAST etc
  my $query_types     = $sd->multi_val('ENSEMBL_BLAST_QUERY_TYPES');        # hashref with keys dna, peptide
  my $db_types        = $sd->multi_val('ENSEMBL_BLAST_DB_TYPES');           # hashref with keys dna, peptide
  my $blast_configs   = $sd->multi_val('ENSEMBL_BLAST_CONFIGS');            # hashref with valid combinations of query_type, db_type, sources, search_type (and program for the search_type)
  my $sources         = $sd->multi_val('ENSEMBL_BLAST_DATASOURCES');        # hashref with keys as blast type and value as a hashref of data sources type and label
  my $sources_ordered = $sd->multi_val('ENSEMBL_BLAST_DATASOURCES_ORDER');  # hashref with keys as blast type and value as a ordered array if data sources type
  my $search_types    = [ map { $_->{'search_type'} } @$blast_configs ];    # NCBIBLAST_BLASTN, NCBIBLAST_BLASTP, BLAT_BLAT etc

  my $options         = {}; # Options for different dropdown fields
  my $missing_sources = {}; # List of missing source files per species

  # Species, query types and db types options
  $options->{'species'}        = [ sort { $a->{'caption'} cmp $b->{'caption'} } map { 'value' => $_, 'caption' => $sd->species_label($_, 1) }, @species ];
  $options->{'query_type'}     = [ map { 'value' => $_, 'caption' => $query_types->{$_} }, keys %$query_types ];
  $options->{'db_type'}        = [ map { 'value' => $_, 'caption' => $db_types->{$_}    }, keys %$db_types    ];

  # Search type options
  foreach my $search_type (@$search_types) {
    my ($blast_type, $search_method) = $self->parse_search_type($search_type);
    push @{$options->{'search_type'}}, { 'value' => $search_type, 'caption' => $search_method };
  }

  # DB Source options
  foreach my $source_type (@$sources_ordered) {
    for (@$blast_configs) {
      if (grep { $source_type eq $_ } @{$_->{'sources'}}) {
        push @{$options->{'source'}{$_->{'db_type'}}}, { 'value' => $source_type, 'caption' => $sources->{$source_type} };
        last;
      }
    }
  }

  # Find the missing source files
  for (@species) {
    my %available_sources = map {$_ => 1} map { keys %$_ } values %{$sd->get_config($_, 'ENSEMBL_BLAST_DATASOURCES')};
    if (my @missing = grep !$available_sources{$_}, keys %$sources) {
      $missing_sources->{$_} = \@missing;
    }
  }

  return {
    'options'         => $options,
    'missing_sources' => $self->jsonify($missing_sources),
    'combinations'    => $self->jsonify($blast_configs)
  };
}

sub get_edit_jobs_data {
  ## Abstract method implementation
  my $self  = shift;
  my $hub   = $self->hub;
  my $jobs  = $self->get_requested_job || $self->get_requested_ticket;
     $jobs  = $jobs ? ref($jobs) =~ /Ticket/ ? $jobs->job : [ $jobs ] : [];

  my @jobs_data;

  if (@$jobs) {

    my %config_fields = map { @$_ } values %{{ @{CONFIGURATION_FIELDS()} }};

    for (@$jobs) {
      my $job_data = $_->job_data->raw;
      delete $job_data->{$_} for qw(source_file output_file);
      $job_data->{'species'}  = $_->species;
      $job_data->{'sequence'} = $self->get_input_sequence_for_job($_);
      for (keys %{$job_data->{'configs'}}) {
        $job_data->{'configs'}{$_} = { reverse %{$config_fields{$_}{'commandline_values'}} }->{ $job_data->{'configs'}{$_} } if exists $config_fields{$_}{'commandline_values'};
      }
      push @jobs_data, $job_data;
    }
  }

  return \@jobs_data;
}

sub get_input_sequence_for_job {
  ## Gets input sequence of a job from input file
  ## @param Job rose object
  ## @return Copy of hashref saved at $job->job_data->{'seuqnece'}, but with two extra keys 'display_id', 'sequence', but one removed key 'input_file'
  my ($self, $job) = @_;

  my $sequence    = $job->job_data->raw->{'sequence'};
  my @fasta_lines = map { chomp; $_ } file_get_contents(sprintf "%s/%s", $job->job_dir, delete $sequence->{'input_file'});

  $sequence->{'display_id'} = $fasta_lines[0] =~ s/^>// ? shift @fasta_lines : '';
  $sequence->{'sequence'}   = join("", @fasta_lines);

  return $sequence;
}

sub get_param_value_caption {
  ## Gets the display caption for a value for a given param type
  ## @param Param type string (query_type, db_type, source or search_type)
  ## @param Value
  ## @return String caption, if param value is valid, undef otherwise
  my ($self, $param_name, $param_value) = @_;

  my $hub = $self->hub;
  my $sd  = $hub->species_defs;

  if ($param_name eq 'search_type') {
    my $blast_types = $sd->multi_val('ENSEMBL_BLAST_TYPES');
    for (@{$sd->multi_val('ENSEMBL_BLAST_CONFIGS')}) {
      if ($param_value eq $_->{'search_type'}) {
        my ($blast_type, $search_method) = $self->parse_search_type($param_value);
        return $search_method eq $blast_types->{$blast_type} ? $search_method : sprintf('%s (%s)', $search_method, $blast_types->{$blast_type});
      }
    }
  } else {

    my %param_type_map = qw(query_type ENSEMBL_BLAST_QUERY_TYPES db_type ENSEMBL_BLAST_DB_TYPES source ENSEMBL_BLAST_DATASOURCES);
    if (my $sd_key = $param_type_map{$param_name}) {
      my $param_details = $sd->multi_val($sd_key);
      return $param_details->{$param_value} if exists $param_details->{$param_value};
    }
  }
}

sub parse_search_type {
  ## Parses the search type value to get blast type and actual search method name
  ## @param Search type string
  ## @param (optional) required key (blast_type or search_method)
  ## @return List of blast_type and search_method values if required key not specified, individual key value otherwise
  my ($self, $search_type, $required_key) = @_;
  my @search_type = split /_/, $search_type;
  if ($required_key) {
    return $search_type[0] if $required_key eq 'blast_type';
    return $search_type[1] if $required_key eq 'search_method';
  }
  return @search_type
}

sub get_target_object {
  ## Gets the target genomic object according to the target Id of the blast result's hit
  ## @param Blast result hit
  ## @param DB Source type
  ## @return PredictionTranscript/Transcript/Translation object
  my ($self, $hit, $source)  = @_;
  my $target_id     = $hit->{'tid'};
  my $species       = $hit->{'species'};
  my $feature_type  = $source =~ /abinitio/i ? 'PredictionTranscript' : $source =~ /cdna|ncrna/i ? 'Transcript' : 'Translation';
  my $adaptor       = $self->hub->get_adaptor("get_${feature_type}Adaptor", 'core', $species);

  return $adaptor->fetch_by_stable_id($target_id);
}

sub map_result_hits_to_karyotype {
  ## Maps all the hit as a feature on the karyotype view
  ## In case some hits are on a patch, it gets the actual chromosome name to draw that hit on the karyotype
  ## @param Job object
  my ($self, $job) = @_;

  my $hub     = $self->hub;
  my $species = $job->species;
  my $results = $job->result;

  my %all_chr = map { $_ => 1 } @{$hub->species_defs->get_config($species, 'ENSEMBL_CHROMOSOMES') || []};
  my %alt_chr;

  my @features;

  for (@$results) {
    my $hit_id  = $_->result_id;
    my $hit     = $_->result_data;
    my $feature = {
      'region'    => $hit->{'gid'},
      'start'     => $hit->{'gstart'},
      'end'       => $hit->{'gend'},
      'p_value'   => 1 + $hit->{'pident'} / 100,
      'strand'    => $hit->{'gori'},
      'href'      => $hub->url('ZMenu', {
        'species'   => $species,
        'type'      => 'Tools',
        'action'    => 'Blast',
        'function'  => '',
        'tl'        => $self->create_url_param,
        'hit'       => $hit_id
      }),
      'html_id'   => "hsp_$hit_id"
    };

    if (!$all_chr{$hit->{'gid'}}) { # if it's a patch region, get the actual chromosome name
      if (!exists $alt_chr{$hit->{'gid'}}) {
        my $slice = $hub->get_adaptor('get_SliceAdaptor')->fetch_by_region('toplevel', $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'});
        my ($alt) = @{$hub->get_adaptor('get_AssemblyExceptionFeatureAdaptor')->fetch_all_by_Slice($slice)};
        my $alt_slice;

        if ($alt) {
          $alt_slice = $alt->alternate_slice;
        }

        $alt_chr{$hit->{'gid'}} = $alt_slice ? $alt_slice->seq_region_name : undef;
      }

      next unless $alt_chr{$hit->{'gid'}};

      $feature->{'actual_region'} = $hit->{'gid'};
      $feature->{'region'}        = $alt_chr{$hit->{'gid'}};
    }

    push @features, $feature;
  }

  return \@features;
}

sub get_all_hits {
  ## Gets all the result hits (hashrefs) for the given job, and adds result_id and tl (url param) to the individual hit
  ## @param Job object
  ## @param Optional sort subroutine to sort the hits (defaults to sorting by result id)
  ## @return Arrayref of hits hashref
  my ($self, $job, $sort) = @_;

  $sort ||= sub { $a->{'result_id'} <=> $b->{'result_id'} };

  $job->load('with' => 'result');

  return [ sort $sort map {

    my $result_id   = $_->result_id;
    my $result_data = $_->result_data->raw;

    $result_data->{'result_id'} = $result_id;
    $result_data->{'tl'}        = $self->create_url_param({'result_id' => $result_id});

    $result_data

  } @{$job->result} ];
}

sub get_all_hits_in_slice_region {
  ## Gets all the result hits for the given job in the given slice region
  ## @param Job object
  ## @param Slice object
  ## @param Sort subroutine as accepted by get_all_hits
  ## @return Array of hits hashrefs
  my ($self, $job, $slice, $sort) = @_;

  my $s_name    = $slice->seq_region_name;
  my $s_start   = $slice->start;
  my $s_end     = $slice->end;

  return [ grep {

    my $gid    = $_->{'gid'};
    my $gstart = $_->{'gstart'};
    my $gend   = $_->{'gend'};

    $s_name eq $gid && (
      $gstart >= $s_start && $gend <= $s_end ||
      $gstart < $s_start && $gend <= $s_end && $gend > $s_start ||
      $gstart >= $s_start && $gstart <= $s_end && $gend > $s_end ||
      $gstart < $s_start && $gend > $s_end && $gstart < $s_end
    )

  } @{$self->get_all_hits($job, $sort)} ];
}

sub get_result_url {
  ## Gets required url links for the result hit
  ## @param Link type (either one of these: target, location, alignment, query_sequence, genomic_sequence)
  ## @param Job object
  ## @param Result object
  ## @return Hashref as accepted by hub->url
  my ($self, $link_type, $job, $result) = @_;

  my $species     = $job->species;
  my $job_data    = $job->job_data;
  my $result_data = $result->result_data;
  my $url_param   = $self->create_url_param({'job_id' => $job->job_id, 'result_id' => $result->result_id});

  if ($link_type eq 'target') {

    my ($param, $gene, $gene_url, $gene_display);

    my $source  = $job_data->{'source'};
    my $target  = $self->get_target_object($result_data, $source);

    if ($target->isa('Bio::EnsEMBL::Translation')) {
      $param  = 'p';
      $target = $target->transcript;
    }

    if ($target->isa('Bio::EnsEMBL::PredictionTranscript')) {
      $param  = 'pt';
    } else { # Bio::EnsEMBL::Transcript
      $param  = 't';
      $gene   = $target->get_Gene;
    }

    if ($gene) {
      $gene_url = {
        'species' => $species,
        'type'    => 'Gene',
        'action'  => 'Summary',
        'g'       => $gene->stable_id,
        'tl'      => $url_param
      };
      $gene_display = $gene->display_xref;
      $gene_display = $gene_display ? $gene_display->display_id : $gene->stable_id;
    }

    my $transcript_url = {
      'species' => $species,
      'type'    => 'Transcript',
      'action'  => $source =~/cdna|ncrna/i ? 'Summary' : 'ProteinSummary',
      $param    => $result_data->{'tid'},
      'tl'      => $url_param
    };

    return wantarray ? ($transcript_url, $gene_url, $gene_display) : $transcript_url;

  } elsif ($link_type eq 'location') {

    my $start   = $result_data->{'gstart'} < $result_data->{'gend'} ? $result_data->{'gstart'} : $result_data->{'gend'};
    my $end     = $result_data->{'gstart'} > $result_data->{'gend'} ? $result_data->{'gstart'} : $result_data->{'gend'};
    my $length  = $end - $start;
    my $p_track = $self->parse_search_type($job->job_data->{'search_type'}, 'search_method') ne 'BLASTN' ? ',codon_seq=normal' : ''; # show translated track for any seach type other than dna vs dna

    # Add 5% padding on both sides
    $start  = int($start - $length * 0.05);
    $start  = 1 if $start < 1;
    $end    = int($end + $length * 0.05);

    return {
      '__clear'           => 1,
      'species'           => $species,
      'type'              => 'Location',
      'action'            => 'View',
      'r'                 => sprintf('%s:%s-%s', $result_data->{'gid'}, $start, $end),
      'contigviewbottom'  => "blast=normal$p_track",
      'tl'                => $url_param
    };

  } elsif ($link_type eq 'alignment') {

    return {
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => $self->get_alignment_component_name_for_job($job),
      'tl'        => $url_param
    };

  } elsif ($link_type eq 'query_sequence') {

    return {
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => 'QuerySeq',
      'tl'        => $url_param
    };

  } elsif ($link_type eq 'genomic_sequence') {

    return {
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => 'GenomicSeq',
      'tl'        => $url_param
    };
  }
}

sub get_alignment_component_name_for_job {
  ## Returns 'Alignment' or 'AlignmentProtein' () depending upon job object
  my ($self, $job) = @_;
  return $job->job_data->{'db_type'} eq 'peptide' || $job->job_data->{'query_type'} eq 'peptide' ? 'AlignmentProtein' : 'Alignment';
}

sub handle_download {
  ## Method reached by url ensembl.org/Download/Blast/
  my ($self, $r) = @_;
  my $job = $self->get_requested_job;

  # TODO redirect to job not found page if !$job

  my $result_file = sprintf '%s/%s', $job->job_dir, $job->job_data->{'output_file'};

  # TODO - result file is missing, or temporarily not available if !-e $result_file

  my $content = join '', file_get_contents($result_file);

  $r->headers_out->add('Content-Type'         => 'text/plain');
  $r->headers_out->add('Content-Length'       => length $content);
  $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s.blast.txt', $self->create_url_param);

  print $content;
}

sub get_hit_genomic_slice {
  ## Gets the genomic slice according to the coordinates returned in the blast results
  ## @param Result hit
  my ($self, $hit, $flank5, $flank3) = @_;
  my $start   = $hit->{'gstart'} < $hit->{'gend'} ? $hit->{'gstart'} : $hit->{'gend'};
  my $end     = $hit->{'gstart'} > $hit->{'gend'} ? $hit->{'gstart'} : $hit->{'gend'};
  my $coords  = $hit->{'gid'}.':'.$start.'-'.$end.':'.$hit->{'gori'};
  my $slice   = $self->hub->get_adaptor('get_SliceAdaptor', 'core', $hit->{'species'})->fetch_by_toplevel_location($coords);
  return $flank5 || $flank3 ? $slice->expand($flank5, $flank3) : $slice;
}

sub map_btop_to_genomic_coords {
  ## Maps the btop format returned by NCBI BLAST to genomic alignment
  ## @param Hit object
  ## @param Job object (needed to cache the mapped genomic aligment for future use)
  my ($self, $hit, $job) = @_;

  my $source  = $hit->{'source'};
  my $galn    = '';

  # don't need to map for other dbs
  return $hit->{'aln'} unless $source =~/cdna|pep/i;

  # find the alignment and cache it in the db in case not already saved
  unless ($galn = $hit->{'galn'}) {

    my $btop            = $hit->{'aln'} =~ s/^\s|\s$//gr;
    my $coords          = $hit->{'g_coords'};
    my $target_object   = $self->get_target_object($hit, $source);
    my $mapping_type    = $source =~/pep/i ? 'pep2genomic' : 'cdna2genomic';
    my $gap_start       = $coords->[0]->end;
    my $gap_count       = scalar @$coords;
    my $processed_gaps  = 0;

    # reverse btop string if necessary so always dealing with + strand genomic coords
    my $object_strand   = $target_object->isa('Bio::EnsEMBL::Translation') ? $target_object->start_Exon->strand : $target_object->strand;
    my $rev_flag        = $object_strand ne $hit->{'tori'};
    $btop               = $self->_reverse_btop($btop) if $rev_flag;

    # account for btop strings that do not start with a match;
    $btop = "0$btop" if $btop !~/^\d+/ ;
    $btop =~s/(\d+)/:$1:/g;
    $btop =~s/^:|:$//g;

    my @btop_features   = split (/:/, $btop);
    my $genomic_start   = $hit->{'gstart'};
    my $genomic_end     = $hit->{'gend'};
    my $genomic_offset  = $genomic_start;
    my $target_offset   = !$rev_flag ? $hit->{'tstart'} : $hit->{'tend'};

    while (my ($num_matches, $diff_string) = splice @btop_features, 0, 2) {

      next unless $diff_string;

      my $diff_length = (length $diff_string) / 2;
      my $temp        = $diff_string;
      my @diffs       = split //, $temp;

      # Account for bases inserted in query relative to target
      my $insert_in_query = 0;

      while (my ($query_base, $target_base) = splice @diffs, 0, 2) {
        $insert_in_query++ if $target_base eq '-' && $query_base ne '-';
      }

      my ($difference_start, $difference_end);

      if ($rev_flag) {
        $difference_end   = $target_offset - $num_matches;
        $difference_start = $difference_end - $diff_length + $insert_in_query + 1;
        $target_offset    = $difference_start - 1;
      } else {
        $difference_start = $target_offset + $num_matches;
        $difference_end   = $difference_start + $diff_length - $insert_in_query - 1;
        $target_offset    = $difference_end + 1;
      }

      my @mapped_coords = sort { $a->start <=> $b->start } grep { ! $_->isa('Bio::EnsEMBL::Mapper::Gap') } $target_object->$mapping_type($difference_start, $difference_end, $hit->{'tori'});
      my $mapped_start  = $mapped_coords[0]->start;
      my $mapped_end    = $mapped_coords[-1]->end;

      # Check that mapping occurs before the next gap
      if ($mapped_start < $gap_start && $mapped_end <= $gap_start) {

        $galn          .= $num_matches;
        $galn          .= $diff_string;
        $genomic_offset = $mapped_end + 1;

      } elsif ($mapped_start > $gap_start) {

        # process any gaps in mapped genomic coords first
        while ($mapped_start > $gap_start) {
          my $matches_before_gap  = $gap_start - $genomic_offset + 1;
          my $gap_end             = $coords->[$processed_gaps + 1]->start -1;
          my $gap_length          = ($gap_end - $gap_start);
          my $gap_string          = '--' x $gap_length;
          $genomic_offset         = $gap_end + 1;

          $galn .= $matches_before_gap;
          $galn .= $gap_string;

          $processed_gaps++;
          $gap_start = $coords->[$processed_gaps]->end || $genomic_end;
        }

        # Add difference info
        my $matches_after_gap = $mapped_start - $genomic_offset;
        $galn .= $matches_after_gap;
        $galn .= $diff_string;
        $genomic_offset = $mapped_end + 1;

      } elsif ($mapped_start < $gap_start && $mapped_end > $gap_start) { # Difference in btop string spans a gap in the genomic coords

        my $diff_matches_before_gap = $gap_start - $mapped_start;
        my $diff_index              = $diff_matches_before_gap * 2 - 1;
        my $diff_before_gap         = join '', @diffs[0..$diff_index];
        $diff_index++;

        $galn .= $num_matches;
        $galn .= $diff_before_gap;

        while ($mapped_end > $gap_start) {
          my $gap_end     = $coords->[$processed_gaps + 1]->start - 1;
          my $gap_length  = ($gap_end - $gap_start);
          my $gap_string  = '--' x $gap_length;
          $processed_gaps++;
          $gap_start = $coords->[$processed_gaps]->end || $genomic_end;

          my $match_number    = $gap_start - $gap_end;
          my $diff_end        = $diff_index + ( $match_number * 2 ) - 1;
          my $diff_after_gap  = join '', @diffs[$diff_index..$diff_end];

          $galn .= $gap_string;
          $galn .= $diff_after_gap;

          $diff_index = $diff_end + 1;
        }

        my $diff_after_gap = join '', @diffs[$diff_index..-1];
        $galn .= $diff_after_gap;

        $genomic_offset = $mapped_end + 1;

      } else {
        warn "Object::Blast::map_btop_to_genomic_coords: mapping case not caught!  $mapped_start $mapped_end $gap_start";
      }
    }

    # Add in any gaps from mapping to genomic coords that occur after last btop feature
    while ($gap_count > $processed_gaps + 1) {
      my $num_matches = $gap_start - $genomic_offset + 1;
      my $gap_end     = $coords->[$processed_gaps + 1]->start - 1;
      my $gap_length  = ($gap_end - $gap_start);
      my $gap_string  = '--' x $gap_length;

      $galn .= $num_matches;
      $galn .= $gap_string;

      $genomic_offset = $gap_end + 1;
      $gap_start      = $coords->[$processed_gaps + 1]->end;
      $processed_gaps++;
    }

    my $btop_end = $genomic_end - $genomic_offset + 1;
    $galn .= $btop_end;

    # Write back to database so we only have to do this once
    if ($job && (my $result_id = $hit->{'result_id'})) {
      my ($result) = grep { $result_id eq $_->result_id} @{$job->result};
      $result->result_data->{'galn'} = $galn;
      $result->save;
    }
  }

  return $galn && $source =~ /latest/i && $hit->{'gori'} ne '1' ? $self->_reverse_btop($galn) : $galn;
}

sub _reverse_btop {
  ## @private
  my ($self, $incoming_btop) = @_;
  $incoming_btop      = uc $incoming_btop;
  my $reversed_btop   = reverse $incoming_btop;
  my @captures        = $reversed_btop =~ /(\d+)([-ACTG]*)/xmsg;
  my $new_btop        = '';
  while (my ($match_number, $btop_states) = splice @captures, 0, 1) {
    $match_number       = reverse $match_number if length "$match_number" > 1;  # reversing the string means numbers like 15 become 51 so we fix it
    my @doubles         = $btop_states =~ /([-ACTG]{2})/xmsg;                   # pairs of chars are taken
    my $new_btop_states = join('', map { my $v = reverse $_; $v; } @doubles);   # we reverse the pairs of chars
    $new_btop          .= $match_number if $match_number;                       # only add the match number if it was defined
    $new_btop          .= $new_btop_states;
  }
  return $new_btop;
}

1;
