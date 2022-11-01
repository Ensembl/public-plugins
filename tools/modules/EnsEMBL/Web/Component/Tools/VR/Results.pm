=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::VR::Results;

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Component::Tools::NewJobButton;
use POSIX qw(ceil);
use EnsEMBL::Web::Utils::FormatText qw(helptip);
use URI::Escape qw(uri_unescape);
use EnsEMBL::Web::Utils::Variation qw(display_items_list);

use parent qw(EnsEMBL::Web::Component::Tools::VR);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $object  = $self->object;
  my $ticket  = $object->get_requested_ticket;
  my $job     = $ticket ? $ticket->job->[0] : undef;

  return '' if !$job || $job->status ne 'done';

  my $job_data  = $job->job_data;
  my $job_config  = $job->dispatcher_data->{'config'};
  my $species   = $job->species;

  my $ticket_name = $object->parse_url_param->{'ticket_name'};

  # THIS OUTPUT IS DEFINED IN THE RUNNABLE
  my $output_file  = 'vr_output';
  my $output_file_json = 'vr_output.json';
  my $output_file_vcf = 'vr_output.vcf';

  my $result_headers = $job_config->{'result_headers'};
  my @headers = @$result_headers;

  # From output file in tab format
  my @content = file_get_contents(join('/', $job->job_dir, $output_file), sub { s/\R/\r\n/r });

  my %params = map { $_ eq 'update_panel' ? () : ($_ => $hub->param($_)) } $hub->param;
  my $html = '';

  my @rows = ();
  foreach my $line (@content) {
    chomp $line;
    next unless $line !~ /^#/;
    my @split     = split /\t/, $line;
    my %row_data  = map { $headers[$_] => $split[$_] } 0..$#headers;
    push @rows, \%row_data;
  }

  # niceify for table
  my %header_titles = (
    'id'                  => 'Variant identifier',
    'hgvsg'               => 'HGVS Genomic',
    'hgvsc'               => 'HGVS Transcript',
    'hgvsp'               => 'HGVS Protein',
    'vcf_string'          => 'VCF format',
    'var_synonyms'        => 'Variant synonyms',
    'mane_select'         => 'MANE Select',
    'spdi'                => 'SPDI',
    'allele'              => 'Allele',
    'input'               => 'Uploaded variant'
  );
  for (grep {/\_/} @headers) {
    $header_titles{$_} ||= $_ =~ s/\_/ /gr;
  }

  my %field_descriptions = (
    'id'                  => 'Variants present in the Ensembl Variation database that are co-located with input',
    'hgvsg'               => 'HGVS genomic sequence name',
    'hgvsc'               => 'HGVS coding sequence name',
    'hgvsp'               => 'HGVS protein sequence name',
    'vcf_string'          => 'Position based name',
    'var_synonyms'        => 'Extra known synonyms for co-located variants',
    'mane_select'         => 'MANE Select (Matched Annotation from NCBI and EMBL-EBI) Transcripts',
    'spdi'                => 'Genomic SPDI notation: NCBI variation notation described as Sequence Position Deletion Insertion (https://www.ncbi.nlm.nih.gov/variation/notation/)',
    'allele'              => 'Alternative allele',
    'input'               => 'Uploaded variant identifier'
  );

  my @table_headers = map {{
    'key' => $_,
    'title' => ($header_titles{$_} || $_),
    'sort' => 'string',
    'help' => $field_descriptions{$_}
  }} @headers;

  my $selected_rows;

  $params{'line_count'} = 0 unless defined ($params{'parsed'});

  my $output_lines = scalar(@rows);

  my ($selected_rows, $line_count) = $self->get_rows(\%params, \@rows, $output_lines);

  my @rows_to_display = @$selected_rows;

  # By default, 20 entries are displayed
  my $size = $params{'size'} || 20;
  my $from = $params{'from'} || 1;
  my $to   = $params{'to'};
  
  my $actual_to = $from - 1 + ($line_count || 0);

  # open toolbox containers div
  $html .= '<div>';
  $html .= '<input type="hidden" class="panel_type" value="VRResults" />';

  # add toolboxes
  my $nav_html = $self->_navigation($actual_to, $output_lines);

  $html .= '<div class="toolbox right-margin">';
  $html .= '<div class="toolbox-head">';
  $html .= '<img src="/i/16/eye.png" style="vertical-align:top;"> ';
  $html .= helptip('Navigation', "Navigate through the results of your Variant Recoder job. By default the results for 20 variants are displayed.");
  $html .= '</div>';
  $html .= '<div style="padding:5px;">'.$nav_html.'</div>';
  $html .= '</div>';

  # download output files
  my $download_html = $self->_download($output_file, $output_file_json, $output_file_vcf, $species);
  $html .= $download_html;

  # new job button
  my $button_url = $hub->url({'function' => undef, 'expand_form' => 'true'});
  my $new_job_button = EnsEMBL::Web::Component::Tools::NewJobButton->create_button( $button_url );
  $html .= '<span class="left-margin">' . $new_job_button . '</span>';

  # close toolboxes container div
  $html .= '</div>';

  # linkify row content
  my $row_id = 0;
  foreach my $row (@rows_to_display) {
    foreach my $header (@headers) {
      if ($row->{$header} && $row->{$header} ne '' && $row->{$header} ne '-') {
        if ($header eq 'id') {
          $row->{$header} = $self->get_items_in_list($row_id, 'id', 'Variant identifier', $row->{$header}, $species);
        }
        elsif ($header eq 'vcf_string') {
          $row->{$header} = $self->get_items_in_list($row_id, 'vcf_string', 'VCF format', $row->{$header}, $species);
        }
        elsif ($header eq 'var_synonyms') {
          $row->{$header} = $self->get_items_in_list($row_id, 'var_synonyms', 'Variant synonyms', $row->{$header}, $species);
        }
        elsif ($header eq 'mane_select') {
          $row->{$header} = $self->get_items_in_list($row_id, 'mane_select', 'MANE Select', $row->{$header}, $species);
        }
        elsif ($header eq 'hgvsc') {
          $row->{$header} = $self->get_items_in_list($row_id, 'hgvsc', 'HGVS Transcript', $row->{$header}, $species, $job_data);
        }
        elsif ($header eq 'hgvsp') {
          $row->{$header} = $self->get_items_in_list($row_id, 'hgvsp', 'HGVS Protein', $row->{$header}, $species, $job_data);
        }
        elsif ($header eq 'spdi') {
          $row->{$header} = $self->get_items_in_list($row_id, 'spdi', 'SPDI', $row->{$header}, $species, $job_data);
        }
        elsif ($header eq 'hgvsg') {
          $row->{$header} = $self->get_items_in_list($row_id, 'hgvsg', 'HGVS Genomic', $row->{$header}, $species, $job_data);
        }
      }
      $row_id++;
    }
  }

  # table with results
  my $table = $self->new_table(\@table_headers, \@rows_to_display, { data_table => 1, exportable => 0, data_table_config => {bLengthChange => 'false', bFilter => 'false'}, hidden_columns => []});
  $html .= $table->render || '<h3>No data</h3>';

  # repeat navigation div under table
  $html .= '<div>'.$nav_html.'</div>';

  $html .= '</div>';

  return $html;
}

# Return the output lines by chunks
sub get_rows {
  my $self = shift;
  my $params = shift;
  my $rows = shift;
  my $output_lines = shift;
  my $line_count = $params->{'line_count'};

  my $from = $params->{'from'} || 1;
  my $to;
  if($output_lines < 20 || $params->{'to'} > $output_lines) {
    $to = $output_lines;
  }
  else {
    $to = $params->{'to'} || 20;
  }
  my $loc  = $params->{'location'};

  my $start = $from - 1;
  my $end = $to - 1;
  my $line_count = $line_count + ($to - $from + 1);
  $params->{'line_count'} = $line_count;
  $params->{'parsed'} = 1;
  my @result_rows;

  my @all_rows = @$rows;

  foreach my $i ($start .. $end) {
    push @result_rows, $all_rows[$i];
  }

  return \@result_rows, $line_count;
}

sub linkify {
  my $self = shift;
  my $field = shift;
  my $values = shift;
  my $species = shift;
  my $job_data = shift;

  # work out core DB type
  my $db_type = 'core';
  if(my $ct = $job_data->{core_type}) {
    if($ct eq 'refseq' || ($values && $ct eq 'merged' && $values !~ /^ENS/)) {
      $db_type = 'otherfeatures';
    }
  }

  my @return_values = ();
  my $new_value;
  my $hub = $self->hub;
  my $sd = $hub->species_defs;

  my @all_values = split(', ', $values);

  foreach my $value (@all_values) {

  return '-' unless defined $value && $value ne '';

  # transcript
  if(($field eq 'hgvsc' || $field eq 'hgvsp') && $value =~ /^ENS/) {
    my $action = $field eq 'hgvsc' ? 'Summary' : 'ProteinSummary';

    my @split_value = split(':', $value);

    my $url = $hub->url({
      type    => 'Transcript',
      action  => $action,
      t       => $split_value[0],
      species => $species,
      db      => $db_type,
    });

    my $zmenu_url = $hub->url({
      type    => 'ZMenu',
      action  => 'Transcript',
      t       => $split_value[0],
      species => $species,
      db      => $db_type,
    });

    $new_value = $self->zmenu_link($url, $zmenu_url, $split_value[0]);
    $new_value .= ":".$split_value[1];
  }
  elsif($field eq 'spdi') {
    my ($chr, $start, $ref, $alt) = split /\:/, $value;
    $start += 1;
    my $end = $start + length($ref) - 1;
    $start -= 3;
    $end += 3;

    my $url = $hub->url({
      type             => 'Location',
      action           => 'View',
      r                => "$chr:$start-$end",
      contigviewbottom => "variation_feature_variation=normal",
      species          => $species
    });

    $new_value = sprintf('<a class="_ht" title="View in location tab" href="%s">%s</a>', $url, $value);
  }
  elsif($field eq 'hgvsg') {
    my ($chr, $desc) = split /\:/, $value;

    my @coords = $desc =~ /([0-9]+)/g;
    my $pos1 = $coords[0];
    my $pos2 = defined($coords[1]) ? $coords[1] : $pos1;
    my $start = $pos1 <= $pos2 ? $pos1 : $pos2;
    my $end = $pos1 <= $pos2 ? $pos2 : $pos1;
    $start -= 3;
    $end += 3;

    my $url = $hub->url({
      type             => 'Location',
      action           => 'View',
      r                => "$chr:$start-$end",
      contigviewbottom => "variation_feature_variation=normal",
      species          => $species
    });

    $new_value = sprintf('<a class="_ht" title="View in location tab" href="%s">%s</a>', $url, $value);
  }
  elsif($field eq 'var_synonyms') {
    my ($source, $synonyms) = split /\: /, $value;
    my @items_with_url_source;

    my @values = split(',', $synonyms);
    my $source_id = $source;
    if(uc $source eq 'CLINVAR') {
        $source_id = 'CLINVAR_VAR';
    }
    if(uc $source eq 'UNIPROT') {
      $source_id = 'UNIPROT_VARIATION';
    }
    if(uc $source eq 'PHARMGKB') {
      $source_id = 'PHARMGKB_VARIANT';
    }

    foreach my $value (@values) {
      my $value_aux = $value;
      if(uc $source eq 'OMIM') {
        $value_aux =~ s/\./#/;
      }
      next if(uc $source eq 'CLINVAR' && $value =~ /^RCV/);
      my $item_url = $hub->get_ExtURL_link($value, $source_id, $value_aux);
      push(@items_with_url_source, uri_unescape($item_url));
    }
    my $new_source = '<b>'.$source.'</b>';
    $new_source =~ s/ /&nbsp;/g;

    $new_value = $new_source.'&nbsp;'.join(', ', @items_with_url_source);
  }
  else {
    $new_value = defined($value) && $value ne '' ? $value : '-';
  }

  push @return_values, $new_value;

  }

  return @return_values;
}

sub linkify_mane {
  my $self = shift;
  my $field = shift;
  my $values = shift;
  my $species = shift;
  my $job_data = shift;
  my $mane_count_g = shift;

  # work out core DB type
  my $db_type = 'core';
  if(my $ct = $job_data->{core_type}) {
    if($ct eq 'refseq' || ($values && $ct eq 'merged' && $values !~ /^ENS/)) {
      $db_type = 'otherfeatures';
    }
  }

  my @return_values = ();
  my %return_values_hgvsg;
  my $new_value;
  my $hub = $self->hub;
  my $sd = $hub->species_defs;

  my @all_values = split(', ', $values);

  foreach my $value (@all_values) {
    return '-' unless defined $value && $value ne '';

    my $mane_result;
    my ($hgvsg, $hgvsc, $hgvsp) = split /\;/, $value;

    if($hgvsc =~ /^ENST/) {
      my @split_value = split(':', $hgvsc);
      my $url = $hub->url({
        type    => 'Transcript',
        action  => 'Summary',
        t       => $split_value[0],
        species => $species,
        db      => $db_type,
      });

      my $zmenu_url = $hub->url({
        type    => 'ZMenu',
        action  => 'Transcript',
        t       => $split_value[0],
        species => $species,
        db      => $db_type,
      });

      my $transc_value = $self->zmenu_link($url, $zmenu_url, $split_value[0]);
      $mane_result = $transc_value.":".$split_value[1];
    }
    else {
      # RefSeq transcripts
      $mane_result = $hgvsc;
    }

    if(defined($hgvsp) && $hgvsp =~ /^ENSP/) {
      my @split_value = split(':', $hgvsp);
      my $url = $hub->url({
        type    => 'Transcript',
        action  => 'ProteinSummary',
        t       => $split_value[0],
        species => $species,
        db      => $db_type,
      });

      my $zmenu_url = $hub->url({
        type    => 'ZMenu',
        action  => 'Transcript',
        t       => $split_value[0],
        species => $species,
        db      => $db_type,
      });

      my $transp_value = $self->zmenu_link($url, $zmenu_url, $split_value[0]);
      $mane_result .= "&nbsp;(".$transp_value.":".$split_value[1].")";
    }
    elsif($hgvsp !~ '-') {
      # RefSeq transcripts
      $mane_result .= "&nbsp;(".$hgvsp.")";
    }

    # Display the HGVS genomic when there are multiple genomic locations
    if(defined($mane_count_g) && $mane_count_g > 1) {
      push @{$return_values_hgvsg{$hgvsg}}, '<li>'. $mane_result . '</li>';
    }
    else {
      $new_value = '<ul class="vr-mane-select"><li>'. $mane_result . '</li></ul>';
      push @return_values, $new_value if $new_value;
    }
  }

  if(defined($mane_count_g) && $mane_count_g > 1) {
    foreach my $hgvsg_key (keys %return_values_hgvsg) {
      my $values = $return_values_hgvsg{$hgvsg_key};
      my $mane_values = join ('', @$values);
      $new_value = '<ul class="vr-mane-select"><li>' . $hgvsg_key . '<ul>' . $mane_values . '</ul>' . '</li></ul>';
      push @return_values, $new_value;
    }
  }

  return @return_values;
}

# Get a list of comma separated items and transforms it into a bullet point list
sub get_items_in_list {
  my $self    = shift;
  my $row_id  = shift;
  my $type    = shift;
  my $label   = shift;
  my $data    = shift;
  my $species = shift;
  my $job_data = shift;

  my $hub = $self->hub;

  my $min_items_count = 5;

  my @items_list = split(', ',$data);
  my @items_with_url;

  if ($type eq 'id') {
    foreach my $item (@items_list) {
      my $item_url = $item;
      if($item =~ /^rs/) {
        my $url = $hub->url({
          type   => 'Variation',
          action => 'Explore',
          v      => $item });
        $item_url = qq{<a href="$url">$item</a>};
      }
      if($item =~ /^COS/) {
        $item_url = $hub->get_ExtURL_link($item, 'COSMIC', $item);
      }
      if($item =~ /^(B|C|H)[A-Z]\d+/) {
        $item_url = $hub->get_ExtURL_link($item, 'HGMD-PUBLIC', $item);
      }
      push(@items_with_url, $item_url);
    }
  }
  elsif ($type eq 'vcf_string') {
    foreach my $item (@items_list) {
      push(@items_with_url, $item);
    }
  }
  elsif ($type eq 'mane_select') {
    my %count_hgvsg;

    # check number of genomic coordinates
    foreach my $item (@items_list) {
      my ($hgvsg, $hgvsc, $hgvsp) = split /;/, $item;
      $count_hgvsg{$hgvsg} = 1;
    }
    my $count_g = keys %count_hgvsg;

    my @items = $self->linkify_mane($type, $data, $species, $job_data, $count_g);
    @items_with_url = @items;
  }

  elsif ($type eq 'hgvsc' || $type eq 'hgvsp' || $type eq 'spdi' || $type eq 'hgvsg' || $type eq 'var_synonyms') {
    foreach my $item (@items_list) {
      my @items = $self->linkify($type, $data, $species, $job_data);
      @items_with_url = @items;
    }
  }

  if (scalar @items_list > $min_items_count) {
    my $div_id = 'row_'.$row_id.'_'.$type;
    return display_items_list($div_id, $type, $label, \@items_with_url, \@items_list);
  }
  else {
    return join('<br />',@items_with_url);
  }
}

## NAVIGATION
#############

sub _navigation {
  my $self = shift;
  my $actual_to = shift;
  my $output_lines = shift;

  my $object = $self->object;
  my $hub = $self->hub;

  # get params
  my %params = map { $_ eq 'update_panel' ? () : ($_ => $hub->param($_)) } $hub->param;
  my $size  = $params{'size'} || 20;
  my $from  = $params{'from'} || 1;
  my $to    = $params{'to'};

  my $orig_size = $size;

  if (defined $to) {
    $size = $to - $from + 1;
  } else {
    $to = $from + $size - 1;
  }

  $actual_to ||= 0;

  my $this_page   = (($from - 1) / $orig_size) + 1;
  my $page_count  = ceil($output_lines / $orig_size);
  my $showing_all = ($to - $from) == ($output_lines - 1) ? 1 : 0;

  my $html = '';

  # navigation
  unless($showing_all) {
    my $style           = 'style="vertical-align:top; height:16px; width:16px"';
    my $disabled_style  = 'style="vertical-align:top; height:16px; width:16px; opacity: 0.5;"';

    $html .= '<b>Page: </b>';

    # first
    if ($from > 1) {
      $html .= $self->reload_link(qq(<img src="/i/nav-l2.gif" $style title="First page"/>), {
        'from' => 1,
        'to'   => $orig_size,
        'size' => $orig_size,
      });
    } else {
      $html .= '<img src="/i/nav-l2.gif" '.$disabled_style.'/>';
    }

    # prev page
    if ($from > 1) {
      $html .= $self->reload_link(sprintf('<img src="/i/nav-l1.gif" %s title="Previous page"/></a>', $style), {
        'from' => $from - $orig_size,
        'to'   => $to - $orig_size,
        'size' => $orig_size,
      });
    } else {
      $html .= '<img src="/i/nav-l1.gif" '.$disabled_style.'/>';
    }

    # page indicator and count
    $html .= sprintf(
      " %i of %s ",
      $this_page,
      (
        $from == 1 && !($to <= $actual_to && $to < $output_lines) ?
        1 : $page_count
      )
    );

    # next page
    if ($to <= $actual_to && $to < $output_lines) {
      $html .= $self->reload_link(sprintf('<img src="/i/nav-r1.gif" %s title="Next page"/></a>', $style), {
        'from' => $from + $orig_size,
        'to'   => $to + $orig_size,
        'size' => $orig_size,
      });
    } else {
      $html .= '<img src="/i/nav-r1.gif" '.$disabled_style.'/>';
    }

    # last
    if ($to < $output_lines) {
      $html .= $self->reload_link(qq(<img src="/i/nav-r2.gif" $style title="Last page"/></a>), {
        'from' => ($size * int($output_lines / $size)) + 1,
        'to'   => $output_lines,
        'size' => $orig_size,
      });
    } else {
      $html .= '<img src="/i/nav-r2.gif" '.$disabled_style.'/>';
    }

    $html .= '<span style="padding: 0px 10px 0px 10px; color: grey">|</span>';
  }

  # number of entries
  $html .= '<b>Show: </b> ';

  foreach my $opt_size (qw(20 50)) {
    next if $opt_size > $output_lines;

    if($orig_size eq $opt_size) {
      $html .= sprintf(' <span class="count-highlight">&nbsp;%s&nbsp;</span>', $opt_size);
    }
    else {
      $html .= ' '. $self->reload_link($opt_size, {
        'from' => $from,
        'to'   => $to + ($opt_size - $size),
        'size' => $opt_size,
      });
    }
  }

  # showing all?
  if ($showing_all) {
    $html .= ' <span class="count-highlight">&nbsp;All&nbsp;</span>';
  } else {
    my $warning = '';
    if($output_lines > 1000) {
      $warning  = '<img class="_ht" src="/i/16/alert.png" style="vertical-align: top;" title="<span style=\'color: yellow; font-weight: bold;\'>WARNING</span>: table with all data may not load in your browser - use Download links instead">';
    }

    $html .=  ' ' . $self->reload_link("All$warning", {
      'from' => 1,
      'to'   => $output_lines,
      'size' => $output_lines,
   });
  }

  $html .= ' variants';
}

## DOWNLOAD
###########

sub _download {
  my $self = shift;
  my $output_file_txt = shift;
  my $output_file_json = shift;
  my $output_file_vcf = shift;
  my $species = shift;

  my $object = $self->object;
  my $hub    = $self->hub;
  my $sd     = $hub->species_defs;

  my $html = '';

  $html .= '<div class="toolbox">';
  $html .= '<div class="toolbox-head"><img src="/i/16/download.png" style="vertical-align:top;"> Download</div><div style="padding:5px;">';

  # all
  $html .= '<div><b>All:</b><span style="float:right; margin-left:10px;">';
  $html .= sprintf(
    ' <a class="_ht" title="Download all results in %s format%s" href="%s">%s</a>',
    $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $object->download_url({output_file => $_ eq 'TXT' ? $output_file_txt : ($_ eq 'JSON' ? $output_file_json : $output_file_vcf)}), $_
  ) for qw(JSON TXT VCF);

  $html .= '</span></div>';

  $html .= '</div></div>';

  return $html;
}

sub reload_link {
  my ($self, $html, $url_params) = @_;

  return sprintf('<a href="%s" class="_reload"><input type="hidden" value="%s" />%s</a>',
    $self->hub->url({%$url_params, 'update_panel' => undef}, undef, 1),
    $self->ajax_url(undef, {%$url_params, 'update_panel' => 1}, undef, 1),
    $html
  );
}

sub zmenu_link {
  my ($self, $url, $zmenu_url, $html) = @_;

  return sprintf('<a class="_zmenu" href="%s">%s</a><a class="hidden _zmenu_link" href="%s"></a>', $url, $html, $zmenu_url);
}

1;
