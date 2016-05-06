=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::VEP::Results;

use strict;
use warnings;

use URI::Escape qw(uri_unescape);
use HTML::Entities qw(encode_entities);
use POSIX qw(ceil);
use Bio::EnsEMBL::Variation::Utils::Constants qw(%OVERLAP_CONSEQUENCES);
use Bio::EnsEMBL::Variation::Utils::VEP qw(@REG_FEAT_TYPES %COL_DESCS);

use parent qw(EnsEMBL::Web::Component::Tools::VEP);

our $MAX_FILTERS = 50;

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $object  = $self->object;
  my $ticket  = $object->get_requested_ticket;
  my $job     = $ticket ? $ticket->job->[0] : undef;

  return '' if !$job || $job->status ne 'done';

  my $job_data  = $job->job_data;
  my $species   = $job->species;
  my @warnings  = grep { $_->data && ($_->data->{'type'} || '') eq 'VEPWarning' } @{$job->job_message};

  # this method reconstitutes the Tmpfile objects from the filenames
  my $output_file_obj = $object->result_files->{'output_file'};

  # get all params
  my %params = map { $_ eq 'update_panel' ? () : ($_ => $hub->param($_)) } $hub->param;

  my $html = '';
  my $ticket_name = $object->parse_url_param->{'ticket_name'};

  # get params
  my $size  = $params{'size'}   || 5;
  my $from  = $params{'from'}   || 1;
  my $to    = $params{'to'};
  my $match = $params{'match'}  || 'and';

  if (defined $to) {
    $size = $to - $from + 1;
  } else {
    $to = $from + $size - 1;
  }

  # define max filters
  my $filter_string = '';
  my $location      = '';

  # construct filter string
  for (1..$MAX_FILTERS) {
    if ($params{"field$_"}) {

      if ($params{"field$_"} eq 'Location') {
        $location .= ' '.$params{"value$_"};
      } else {
        $filter_string .= sprintf('%s%s %s %s',
          ($filter_string ? " $match " : ''),
          $params{"field$_"},
          $params{"operator$_"},
          $params{"operator$_"} eq 'in' ? $params{"value_dd$_"} : $params{"value$_"}
        );
      }
    }
  }

  $filter_string  =~ s/^\s+//g;
  $location       =~ s/^\s+//g;

  # READ DATA
  ###########

  my %content_args = (
    from      => $from,
    to        => $to,
    filter    => $filter_string,
    location  => $location
  );

  my ($header_hash, $rows, $line_count) = @{$output_file_obj->content_parsed(\%content_args)};

  my $headers = $header_hash->{'combined'};
  my $header_extra_descriptions = $header_hash->{'descriptions'} || {};

  my $actual_to = $from - 1 + ($line_count || 0);
  my $row_count = scalar @$rows;

  # niceify for table
  my %header_titles = (
    'ID'                  => 'Uploaded variant',
    'MOTIF_NAME'          => 'Motif name',
    'MOTIF_POS'           => 'Motif position',
    'MOTIF_SCORE_CHANGE'  => 'Motif score change',
    'DISTANCE'            => 'Distance to transcript',
    'EXON'                => 'Exon',
    'INTRON'              => 'Intron',
    'CLIN_SIG'            => 'Clinical significance',
    'BIOTYPE'             => 'Biotype',
    'PUBMED'              => 'Pubmed',
    'HIGH_INF_POS'        => 'High info position',
    'CELL_TYPE'           => 'Cell type',
    'CANONICAL'           => 'Canonical',
    'SYMBOL'              => 'Symbol',
    'SYMBOL_SOURCE'       => 'Symbol source',
    'DOMAINS'             => 'Domains',
    'STRAND'              => 'Feature strand',
    'TSL'                 => 'Transcript support level',
    'STRAND'              => 'Feature strand',
    'SOMATIC'             => 'Somatic status',
    'PICK'                => 'Selected annotation',
    'SOURCE'              => 'Transcript source',
    'IMPACT'              => 'Impact',
    'PHENO'               => 'Phenotype or disease',
    'Existing_variation'  => 'Existing variant',
    'REFSEQ_MATCH'        => 'RefSeq match',
    'HGVS_OFFSET'         => 'HGVS offset',
  );
  for (grep {/\_/} @$headers) {
    $header_titles{$_} ||= $_ =~ s/\_/ /gr;
  }

  # hash for storing seen IDs, used to link to BioMart
  my %seen_ids;

  # linkify row content
  foreach my $row (@$rows) {

    # store IDs
    push @{$seen_ids{'vars'}}, $row->{'Existing_variation'} if defined $row->{'Existing_variation'} && $row->{'Existing_variation'} =~ /\w+/;
    push @{$seen_ids{'genes'}}, $row->{'Gene'} if defined $row->{'Gene'} && $row->{'Gene'} =~ /\w+/;

    # linkify content
    $row->{$_} = $self->linkify($_, $row->{$_}, $species, $job_data) for @$headers;
  }

  # extras
  my %table_sorts = (
    'Location'            => 'position_html',
    'GMAF'                => 'hidden_position',
    'cDNA_position'       => 'numeric',
    'CDS_position'        => 'numeric',
    'Protein_position'    => 'numeric',
    'MOTIF_POS'           => 'numeric',
    'MOTIF_SCORE_CHANGE'  => 'numeric',
    'SIFT'                => 'hidden_position',
    'PolyPhen'            => 'hidden_position',
    'AFR_MAF'             => 'numeric',
    'AMR_MAF'             => 'numeric',
    'ASN_MAF'             => 'numeric',
    'EUR_MAF'             => 'numeric',
    'EAS_MAF'             => 'numeric',
    'SAS_MAF'             => 'numeric',
    'AA_MAF'              => 'numeric',
    'EA_MAF'              => 'numeric',
    'DISTANCE'            => 'numeric',
    'EXON'                => 'hidden_position',
    'INTRON'              => 'hidden_position'
  );

  my @table_headers = map {{
    'key' => $_,
    'title' => ($header_titles{$_} || $_).($COL_DESCS{$_} ? '' : '<sup style="color:grey">(p)</sup>'),
    'sort' => $table_sorts{$_} || 'string',
    'help' => $COL_DESCS{$_} || $header_extra_descriptions->{$_},
  }} @$headers;

  $html .= '<div><h3>Results preview</h3>';
  $html .= '<input type="hidden" class="panel_type" value="VEPResults" />';
  $html .= $self->_warning('Some errors occurred while running VEP', sprintf '<pre class="tools-warning">%s</pre>', join "\n", map $_->display_message, @warnings) if @warnings;

  # construct hash for autocomplete
  my $vdbc = $sd->get_config($species, 'databases')->{'DATABASE_VARIATION'};

  my %ac = (
    'Allele'        => [ 'A', 'C', 'G', 'T' ],
    'Feature_type'  => [ 'Transcript', @REG_FEAT_TYPES ],
    'Consequence'   => [ keys %OVERLAP_CONSEQUENCES ],
    'IMPACT'        => [ keys %{{map {$_->impact => 1} values %OVERLAP_CONSEQUENCES}} ],
    'SIFT'          => [ map {s/ /\_/g; s/\_\-\_/\_/g; $_} @{$vdbc->{'SIFT_VALUES'}} ],
    'PolyPhen'      => [ map {s/\s/\_/g; $_} @{$vdbc->{'POLYPHEN_VALUES'}} ],
    'BIOTYPE'       => $sd->get_config($species, 'databases')->{'DATABASE_CORE'}->{'tables'}{'transcript'}{'biotypes'},
  );

  my $ac_json = encode_entities($self->jsonify(\%ac));
  $html .= qq(<input class="js_param" type="hidden" name="auto_values" value="$ac_json" />);

  # open toolbox containers div
  $html .= '<div>';

  # add toolboxes
  my $nav_html = $self->_navigation($actual_to, $filter_string || $location);

  # navigation HTML we frame here as we want to reuse it unframed after the results table
  $html .= '<div class="toolbox">';
  $html .= '<div class="toolbox-head">';
  $html .= '<img src="/i/16/eye.png" style="vertical-align:top;"> ';
  $html .= $self->helptip('Navigation', "Navigate through the results of your VEP job. By default the results for 5 variants are displayed; note that variants may have more than one result if they overlap multiple transcripts");
  $html .= '</div>';
  $html .= '<div style="padding:5px;">'.$nav_html.'</div>';
  $html .= '</div>';

  # these are framed within the subroutine
  my ($filter_html, $active_filters) = @{$self->_filters($headers, \%header_titles)};
  $html .= $filter_html;

  my $download_html = $self->_download(\%content_args, \%seen_ids, $species);
  $html .= $download_html;

  # close toolboxes container div
  $html .= '</div>';

  # render table
  my $table = $self->new_table(\@table_headers, $rows, { data_table => 1, sorting => [ 'Location asc' ], exportable => 0, data_table_config => {bLengthChange => 'false', bFilter => 'false'}, });
  $html .= $table->render || '<h3>No data</h3>';

  # repeat navigation div under table
  $html .= '<div>'.$nav_html.'</div>';

  $html .= '</div>';

  return $html;
}

## NAVIGATION
#############

sub _navigation {
  my $self = shift;
  my $actual_to = shift;
  my $filter_string_or_location = shift;

  my $object = $self->object;
  my $hub = $self->hub;

  my $stats = $self->job_statistics;
  my $output_lines = $stats->{'General statistics'}->{'Lines of output written'} || 0;

  # get params
  my %params = map { $_ eq 'update_panel' ? () : ($_ => $hub->param($_)) } $hub->param;
  my $size  = $params{'size'} || 5;
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
        1 :
        (
          $filter_string_or_location ? 
          '<span class="ht _ht" title="Result count cannot be calculated with filters enabled">?</span>' :
          $page_count
        )
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
    if ($to < $output_lines && !$filter_string_or_location) {
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

  foreach my $opt_size (qw(1 5 10 50)) {
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
    if($output_lines > 500) {
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

## FILTERS
##########

sub _filters {
  my $self = shift;
  my $headers = shift;
  my $header_titles = shift;

  my $hub = $self->hub;
  my %params = map { $_ eq 'update_panel' ? () : ($_ => $hub->param($_)) } $hub->param;
  my $match = $params{'match'}  || 'and';
  my $html = '';

  $html .= '<div class="toolbox">';
  $html .= '<div class="toolbox-head"><img src="/i/16/search.png" style="vertical-align:top;"> ';
  $html .= $self->helptip('Filters', "Filter your results to find interesting or significant data. You can apply several filters on any category of data in your results using a range of operators, add multiple filters, and edit active filters");
  $html .= '</div>';
  $html .= '<div style="padding:0px 5px 0px 5px;">';

  my $form_url = $hub->url();
  my $ajax_url = $self->ajax_url(undef, {'update_panel' => 1, '__clear' => 1});

  my $ajax_html .= qq(<form action="#" class="_apply_filter" style="margin: 0;"><input type="hidden" name="ajax_url" value="$ajax_url" />);

  # define operators
  my @operators = (
    {'name' => 'is',  'title' => 'is'},
    {'name' => 'ne',  'title' => 'is not'},
    {'name' => 're',  'title' => 'matches'},
    {'name' => 'lt',  'title' => '<'},
    {'name' => 'gt',  'title' => '>'},
    {'name' => 'lte', 'title' => '<='},
    {'name' => 'gte', 'title' => '>='},
    {'name' => 'in',  'title' => 'in file'},
  );
  my @non_numerical = @operators[0..2];
  my %operators = map {$_->{'name'} => $_->{'title'}} @operators;

  # active filters
  my $active_filters = 0;
  my $filter_number;

  my @filter_divs;
  my @location_divs;

  my @user_files =
    sort { $b->{'timestamp'} <=> $a->{'timestamp'} }
    grep { $_->{'format'} && lc($_->{'format'}) eq 'gene_list' }
    $hub->session->get_data('type' => 'upload'), $hub->user ? $hub->user->uploads : ();

  my %file_display_name = map { $_->{file} => $_->{name} } @user_files;

  $html .= '<div>';
  foreach my $i (1..$MAX_FILTERS) {
    if ($params{"field$i"}) {
      my $tmp_html;

      $active_filters++;

      # filter display
      $tmp_html .= sprintf('
        <div class="filter filter_edit_%s">
          %s %s %s
          <span style="float:right; vertical-align: top;">
            <a href="#" class="filter_toggle" rel="filter_edit_%s"><img class="_ht" src="/i/16/pencil-whitebg.png" title="Edit filter"></a>
            %s
          </span>
        </div>',
        $i,
        $header_titles->{$params{"field$i"}} || $params{"field$i"},
        $operators{$params{"operator$i"}},
        $params{"operator$i"} eq 'in' ? $file_display_name{$params{"value_dd$i"}} : ($params{"value$i"} ne "" ? $params{"value$i"} : 'defined'),
        $i,
        $self->reload_link('<img class="_ht" src="/i/close.png" title="Remove filter" style="height:16px; width:16px">', {
          "field$i"       => undef,
          "operator$i"    => undef,
          "value$i"       => undef,
          "value_dd$i"    => undef,
          'update_panel'  => undef
        })
      );

      # edit filter
      $tmp_html .= qq(<div class="filter_edit_$i" style="display:none;">);
      $tmp_html .= $ajax_html;

      # field
      $tmp_html .= qq('<select class="autocomplete" name="field$i">);
      $tmp_html .= sprintf(
        '<option value="%s" %s>%s</option>',
        $_,
        $_ eq $params{"field$i"} ? 'selected="selected"' : '',
        $header_titles->{$_} || $_
      ) for @$headers;
      $tmp_html .= '</select>';

      # operator
      $tmp_html .= qq(<select name="operator$i" class="_operator_dd">);
      $tmp_html .= sprintf(
        '<option value="%s" %s>%s</option>',
        $_->{'name'},
        ($_->{'name'} eq $params{"operator$i"} ? 'selected="selected"' : ''),
        $_->{'title'}
      ) for @operators;
      $tmp_html .= '</select>';

      # value and submit
      $tmp_html .= sprintf(
        qq(<input class="autocomplete _value_switcher %s" type="text" placeholder="defined" name="value$i" value="%s" />),
        $params{"operator$i"} eq 'in' ? 'hidden' : '',
        $params{"value$i"}
      );

      # value (dropdown file selector)
      $tmp_html .= sprintf(
        '<span class="_value_switcher %s">',
        $params{"operator$i"} eq 'in' ? '' : 'hidden'
      );
      if(scalar @user_files) {
        $tmp_html .= '<select name="value_dd'.$i.'">';
        $tmp_html .= sprintf(
          '<option value="%s" %s>%s</option>',
          $_->{file},
          $_->{file} eq $params{"value_dd$i"} ? 'selected="selected"' : '',
          $_->{name}
        ) for @user_files;
        $tmp_html .= '</select>';
      }
      my $url = $hub->url({
        type   => 'UserData',
        action => 'SelectFile',
        # format => 'GENE_LIST'
      });
      $tmp_html .= '<span class="small"> <a href="'.$url.'" class="modal_link data" rel="modal_user_data">Upload file</a> </span>';
      $tmp_html .= '</span>';

      # update/submit
      $tmp_html .= '<input value="Update" class="fbutton" type="submit" />';

      # add hidden fields
      $tmp_html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for grep {!/[a-z]$i$/i} keys %params;
      $tmp_html .= '</form>';
      $tmp_html .= qq(<div style="padding-left: 2px;"><a href="#" class="small filter_toggle" style="color:white;" rel="filter_edit_$i">Cancel</a></div>);
      $tmp_html .= '</div>';

      if($params{"field$i"} =~ /^Location/) {
        push @location_divs, $tmp_html;
      } else {
        push @filter_divs, $tmp_html;
      }
    } else {
      $filter_number ||= $i;
    }
  }

  foreach my $div (@location_divs) {
    $html .= qq(<div class="location-filter-box filter-box">$div</div>);
  }
  # $html .= '<hr style="margin:2px"/>' if scalar @location_divs && scalar @filter_divs;

  foreach my $div (@filter_divs) {
    $html .= qq(<div class="filter-box">$div</div>);
  }

  $html .= '</div>';

  if ($active_filters > 1) {
    my %logic = (
      'or'  => 'any',
      'and' => 'all',
    );

    # clear
    $html .= '<div style="float:left;">'.$ajax_html;
    $html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for grep {!/(field|operator|value|match)/} keys %params;
    $html .= '<input value="Clear filters" class="fbutton" type="submit">';
    $html .= '</form></div>';

    if(scalar @filter_divs > 1) {
      $html .= '<div style="float:right;">'.$ajax_html;
      $html .= 'Match <select name="match"">';
      $html .= sprintf('<option value="%s" %s>%s</option>', $_, ($_ eq $match ? 'selected="selected"' : ''), $logic{$_}) for sort keys %logic;
      $html .= '</select> of the above rules ';
      $html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for grep {!/match/} keys %params;
      $html .= '<input value="Update" class="fbutton" type="submit">';
      $html .= '</form></div>';
    }
  }

  # start form
  #$html .= sprintf('<div style="display:inline-block;"><form action="%s" method="get">', $form_url);
  $html .= '<div style="clear: left;">';

  # $html .= '<hr style="margin:2px"/>' if $active_filters;
  $html .= $ajax_html;

  # field
  $html .= '<select class="autocomplete" name="field'.$filter_number.'">';
  $html .= sprintf('<option value="%s">%s</option>', $_, $header_titles->{$_} || $_) for @$headers;
  $html .= '</select>';

  # operator
  $html .= '<select class="_operator_dd" name="operator'.$filter_number.'">';
  $html .= sprintf('<option value="%s" %s>%s</option>', $_->{name}, ($_->{name} eq 'is' ? 'selected="selected"' : ''), $_->{title}) for @operators;
  $html .= '</select>';

  # value (text box)
  $html .= '<input class="autocomplete _value_switcher" type="text" placeholder="defined" name="value'.$filter_number.'">';

  # value (dropdown file selector)
  $html .= '<span class="_value_switcher hidden">';
  if(scalar @user_files) {
    $html .= '<select name="value_dd'.$filter_number.'">';
    $html .= sprintf('<option value="%s">%s</option>', $_->{file}, $_->{name}) for @user_files;
    $html .= '</select>';
  }
  my $url = $hub->url({
    type   => 'UserData',
    action => 'SelectFile',
    # format => 'GENE_LIST'
  });
  $html .= '<span class="small"> <a href="'.$url.'" class="modal_link data" rel="modal_user_data">Upload file</a> </span>';
  $html .= '</span>';

  # submit
  $html .= '<input value="Add" class="fbutton" type="submit">';

  # add hidden fields
  $html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for keys %params;
  $html .= '</form></div>';

  $html .= '</div></div>';

  return [$html, $active_filters];
}


## DOWNLOAD
###########

sub _download {
  my $self = shift;
  my $content_args = shift;
  my $seen_ids = shift;
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
    $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $object->download_url({ 'format' => lc $_ }), $_
  ) for qw(VCF VEP TXT);
  $html .= '</span></div>';

  # filtered
  if($content_args->{filter}) {

    $html .= '<div style="margin-top: 5px"><b>Filtered:</b><span style="float:right; margin-left:10px;">';
    $html .= sprintf(
      ' <a class="_ht" title="Download filtered results in %s format%s" href="%s">%s</a>',
      $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $object->download_url({ 'format' => lc $_, map {$_ => $content_args->{$_}} grep {!/to|from/} keys %$content_args }), $_
    ) for qw(VCF VEP TXT);
    $html .= '</span></div>';
  }


  ## BIOMART
  ##########

  if($sd->ENSEMBL_MART_ENABLED) {

    # uniquify lists, retain order
    foreach my $key(keys %$seen_ids) {
      my %tmp_seen;
      my @tmp_list;

      foreach my $item(@{$seen_ids->{$key}}) {
        push @tmp_list, $item unless $tmp_seen{$item};
        $tmp_seen{$item} = 1;
      }

      $seen_ids->{$key} = \@tmp_list;
    }

    # generate mart species name
    my @split = split /\_/, $species;
    my $m_species = lc(substr($split[0], 0, 1)).$split[1];

    my $var_mart_url =
      '/biomart/martview?VIRTUALSCHEMANAME=default'.
      '&ATTRIBUTES='.
      $m_species.'_snp.default.snp.refsnp_id|'.
      $m_species.'_snp.default.snp.refsnp_source|'.
      $m_species.'_snp.default.snp.chr_name|'.
      $m_species.'_snp.default.snp.chrom_start'.
      '&FILTERS='.
      $m_species.'_snp.default.filters.snp_filter.%22'.join(",", @{$seen_ids->{vars} || []}).'%22'.
      '&VISIBLEPANEL=filterpanel';

    my $gene_mart_url =
      '/biomart/martview?VIRTUALSCHEMANAME=default'.
      '&ATTRIBUTES='.
      $m_species.'_gene_ensembl.default.feature_page.ensembl_gene_id|'.
      $m_species.'_gene_ensembl.default.feature_page.chromosome_name|'.
      $m_species.'_gene_ensembl.default.feature_page.start_position|'.
      $m_species.'_gene_ensembl.default.feature_page.end_position'.
      '&FILTERS='.
      $m_species.'_gene_ensembl.default.filters.ensembl_gene_id.%22'.join(",", @{$seen_ids->{genes} || []}).'%22'.
      '&VISIBLEPANEL=filterpanel';

    $html .= '<div style="margin-top: 5px"><b>BioMart:</b><span style="float:right; margin-left:10px;">';

    $html .= $seen_ids->{vars} ? sprintf(
      '<a class="_ht" title="Query BioMart with co-located variants in this view" rel="external" href="%s">Variants</a> ',
      $var_mart_url) : 'Variants ';

    $html .= $seen_ids->{genes} ? sprintf(
      '<a class="_ht" title="Query BioMart with genes in this view" rel="external" href="%s">Genes</a>',
      $gene_mart_url) : 'Genes ';

    $html .= '</div>';
  }

  $html .= '</div></div>';

  return $html;
}

sub linkify {
  my $self = shift;
  my $field = shift;
  my $value = shift;
  my $species = shift;
  my $job_data = shift;

  # work out core DB type
  my $db_type = 'core';
  if(my $ct = $job_data->{core_type}) {
    if($ct eq 'refseq' || ($value && $ct eq 'merged' && $value !~ /^ENS/)) {
      $db_type = 'otherfeatures';
    }
  }

  my $new_value;
  my $hub = $self->hub;
  my $sd = $hub->species_defs;

  return '-' unless defined $value && $value ne '';

  $value =~ s/\,/\, /g;

  # location
  if($field eq 'Location') {
    my ($c, $s, $e) = split /\:|\-/, $value;
    $e ||= $s;
    $s -= 50;
    $e += 50;

    my $url = $hub->url({
      type             => 'Location',
      action           => 'View',
      r                => "$c:$s-$e",
      contigviewbottom => "variation_feature_variation=normal",
      species          => $species
    });

    $new_value = sprintf('<a class="_ht" title="View in location tab" href="%s">%s</a>', $url, $value);
  }

  # existing variation
  elsif($field eq 'Existing_variation' && $value =~ /\w+/) {

    foreach my $var(split /\,\s*/, $value) {

      my $url = $hub->url({
        type    => 'Variation',
        action  => 'Explore',
        v       => $var,
        species => $species
      });

      my $zmenu_url = $hub->url({
        type    => 'ZMenu',
        action  => 'Variation',
        v       => $var,
        species => $species
      });

      $new_value .= ($new_value ? ', ' : '').$self->zmenu_link($url, $zmenu_url, $var);
    }
  }

  # transcript
  elsif($field eq 'Feature' && $value =~ /^ENS.{0,3}T\d+$/) {

    my $url = $hub->url({
      type    => 'Transcript',
      action  => 'Summary',
      t       => $value,
      species => $species,
      db      => $db_type,
    });

    my $zmenu_url = $hub->url({
      type    => 'ZMenu',
      action  => 'Transcript',
      t       => $value,
      species => $species,
      db      => $db_type,
    });

    $new_value = $self->zmenu_link($url, $zmenu_url, $value);
  }

  # reg feat
  elsif($field eq 'Feature' && $value =~ /^ENS.{0,3}R\d+$/) {

    my $url = $hub->url({
      type    => 'Regulation',
      action  => 'Summary',
      rf      => $value,
      species => $species
    });

    my $zmenu_url = $hub->url({
      type    => 'ZMenu',
      action  => 'Regulation',
      rf      => $value,
      species => $species
    });

    $new_value = $self->zmenu_link($url, $zmenu_url, $value);
  }

  # gene
  elsif($field eq 'Gene' && $value =~ /\w+/) {

    my $url = $hub->url({
      type    => 'Gene',
      action  => 'Summary',
      g       => $value,
      species => $species,
      db      => $db_type,
    });

    my $zmenu_url = $hub->url({
      type    => 'ZMenu',
      action  => 'Gene',
      g       => $value,
      species => $species,
      db      => $db_type,
    });

    $new_value = $self->zmenu_link($url, $zmenu_url, $value);
  }

  # Protein
  elsif($field eq 'ENSP' && $value =~ /\w+/) {
    my $url = $hub->url({
      type    => 'Transcript',
      action  => 'ProteinSummary',
      p       => $value,
      species => $species
    });

    $new_value = sprintf('<a href="%s">%s</a>', $url, $value);
  }

  # consequence type
  elsif($field eq 'Consequence' && $value =~ /\w+/) {
    my $cons = \%OVERLAP_CONSEQUENCES;
    my $var_styles   = $sd->colour('variation');
    my $colourmap    = $hub->colourmap;

    foreach my $con(split /\,\s+/, $value) {
      $new_value .= $new_value ? ', ' : '';

      if(defined($cons->{$con})) {
        my $colour = $colourmap->hex_by_name($var_styles->{lc $con}->{'default'}) if defined $var_styles->{lc $con};
        $colour  ||= 'no_colour';

        $new_value .=
          sprintf(
            '<nobr><span class="colour" style="background-color:%s">&nbsp;</span> '.
            '<span class="_ht ht" title="%s">%s</span></nobr>',
            $colour, $cons->{$con}->description, $con
          );
      }
      else {
        $new_value .= $con;
      }
    }
  }

  # HGVS
  elsif($field =~ /^(hgvs|csn)/i && $value =~ /\w+/) {
    $new_value = uri_unescape($value);
  }

  # CCDS
  elsif($field eq 'CCDS' && $value =~ /\w+/) {
    $new_value = $hub->get_ExtURL_link($value, 'CCDS', $value)
  }

  # SIFT/PolyPhen/Condel
  elsif($field =~ /sift|polyphen|condel/i && $value =~ /\w+/) {
    my ($pred, $score) = split /\(|\)/, $value;
    $pred =~ s/\_/ /g if $pred;
    $new_value = $self->render_sift_polyphen($pred, $score);
  }

  # LoFTool
  elsif($field =~ /loftool/i && $value =~ /\d+/) {
    my @preds = ('probably damaging', 'possibly damaging', 'benign');

    my $pred = $preds[int(($value - 10e-6) * scalar @preds)];
    $new_value = $self->render_sift_polyphen($pred, $value);
  }

  # codons
  elsif($field eq 'Codons' && $value =~ /\w+/) {
    $new_value = $value;
    $new_value =~ s/([A-Z]+)/<b>$1<\/b>/g;
    $new_value = uc($new_value);
  }

  else {
    $new_value = defined($value) && $value ne '' ? $value : '-';
  }

  return $new_value;
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
