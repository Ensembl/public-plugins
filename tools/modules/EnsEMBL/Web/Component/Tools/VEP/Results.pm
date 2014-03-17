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

package EnsEMBL::Web::Component::Tools::VEP::Results;

use strict;
use warnings;
no warnings 'uninitialized';

use URI::Escape qw(uri_unescape);
use Bio::EnsEMBL::Variation::Utils::Constants qw(%OVERLAP_CONSEQUENCES);
use Bio::EnsEMBL::Variation::Utils::VEP qw(@REG_FEAT_TYPES %COL_DESCS);

use base qw(EnsEMBL::Web::Component::Tools::VEP);

sub content {
  my $self   = shift;
  my $hub    = $self->hub;
  my $object = $self->object;
  my $ticket = $object->get_requested_ticket;
  
  return '<div><h3>No ticket selected</h3></div>' unless defined $ticket;
  
  my $job    = ($ticket->job)[0];
  
  return '<div><h3>No job selected</h3></div>' unless defined $job;
  
  return unless defined $job && $job->status eq 'done';
  
  my $job_data = $job->job_data;
  my $species  = $job->species;
  
  # this method reconstitutes the Tmpfile objects from the filenames
  my $output_file_obj = $object->result_files->{'output_file'};
  
  # get job stats
  my $stats = $self->job_statistics;
  my $output_lines = $stats->{'General statistics'}->{'Lines of output written'} || 0;
  
  # get all params
  my %params;
  foreach my $p($hub->param) {
    next if $p eq 'update_panel';
    foreach my $v($hub->param($p)) {
      $params{$p} = $v;
    }
  }
  
  my $html;
  my $ticket_name = $self->object->parse_url_param->{'ticket_name'};
  
  # get params
  my $size  = $params{size} || 5;
  my $from  = $params{from} || 1;
  my $to    = $params{to};
  my $match = $params{match} || 'and';
  
  if(defined($to)) {
    $size = ($to - $from) + 1;
  }
  else {
    $to = ($from + ($size - 1));
  }
  
  # define max filters
  my $max_filters = 50;
  my ($filter_string, $location);
  
  # construct filter string
  for my $i(1..$max_filters) {
    if($params{"field$i"}) {
      
      if($params{"field$i"} eq 'Location') {
        $location .= " ".$params{"value$i"};
      }
      else {
        $filter_string .= sprintf('%s%s %s %s',
          ($filter_string ? " $match " : ''),
          $params{"field$i"},
          $params{"operator$i"},
          $params{"value$i"}
        );
      }
    }
  }
  
  $filter_string =~ s/^\s+//g;
  $location =~ s/^\s+//g;
  
  
  # READ DATA
  ###########
  
  my %content_args = (
    from => $from,
    to => $to,
    filter => $filter_string,
    location => $location
  );
  
  my ($headers, $rows, $line_count) = @{$output_file_obj->parse_content($output_file_obj->content(%content_args))};
  my $actual_to = ($from + $line_count) - 1;
  my $row_count = scalar @$rows;
  
  # niceify for table
  my %header_titles = (
    'ID' => 'Uploaded variation',
    'MOTIF_NAME' => 'Motif name',
    'MOTIF_POS' => 'Motif position',
    'MOTIF_SCORE_CHANGE' => 'Motif score change',
    'DISTANCE' => 'Distance to transcript',
    'EXON' => 'Exon',
    'INTRON' => 'Intron',
    'CLIN_SIG'     => 'Clinical significance',
    'BIOTYPE'      => 'Biotype',
    'PUBMED'       => 'Pubmed',
    'HIGH_INF_POS' => 'High info position',
    'CELL_TYPE' => 'Cell type',
    'CANONICAL' => 'Canonical',
    'SYMBOL' => 'Symbol',
    'SYMBOL_SOURCE' => 'Symbol source',
    'DOMAINS' => 'Domains',
    'STRAND' => 'Feature strand',
  );
  foreach my $header(grep {/\_/} @$headers) {
    my $tmp = $header;
    $tmp =~ s/\_/ /g;
    $header_titles{$header} ||= $tmp;
  }
  
  # hash for storing seen IDs, used to link to BioMart
  my %seen_ids;
  
  # linkify row content
  foreach my $row(@$rows) {
    
    # store IDs
    push @{$seen_ids{vars}}, $row->{Existing_variation} if defined($row->{Existing_variation}) && $row->{Existing_variation} =~ /\w+/;
    push @{$seen_ids{genes}}, $row->{Gene} if defined($row->{Gene}) && $row->{Gene} =~ /\w+/;
    
    # linkify content
    $row->{$headers->[$_]} = $self->linkify($headers->[$_], $row->{$headers->[$_]}, $species) for (0..$#{$headers});
  }
  
  # extras
  my %table_sorts = (
    Location => 'position_html',
    GMAF => 'hidden_position',
    cDNA_position => 'numeric',
    CDS_position => 'numeric',
    Protein_position => 'numeric',
    MOTIF_POS => 'numeric',
    MOTIF_SCORE_CHANGE => 'numeric',
    SIFT => 'hidden_position',
    PolyPhen => 'hidden_position',
    AFR_MAF => 'numeric',
    AMR_MAF => 'numeric',
    ASN_MAF => 'numeric',
    EUR_MAF => 'numeric',
    AA_MAF => 'numeric',
    EA_MAF => 'numeric',
    DISTANCE => 'numeric',
    EXON => 'hidden_position',
    INTRON => 'hidden_position'
  );
  
  my @table_headers = map {{ key => $_, title => $header_titles{$_} || $_, sort => $table_sorts{$_} || 'string', help => $COL_DESCS{$_}}} @$headers;

  $html .= '<div><h3>Results preview</h3>';
  $html .= '<input type="hidden" class="panel_type" value="VEPResults" />';
  
  # construct hash for autocomplete
  my $vdbc = $hub->species_defs->get_config($species, 'databases')->{'DATABASE_VARIATION'};
  
  my %ac = (
    Allele => [
      'A', 'C', 'G', 'T'
    ],
    Feature_type => [
      'Transcript', @REG_FEAT_TYPES
    ],
    Consequence => [
      keys %OVERLAP_CONSEQUENCES
    ],
    SIFT => $vdbc->{'SIFT_VALUES'},
    PolyPhen => $vdbc->{'POLYPHEN_VALUES'},
    BIOTYPE => $hub->species_defs->get_config($species, 'databases')->{'DATABASE_CORE'}->{'tables'}{'transcript'}{'biotypes'},
  );
  
  my $ac_json = $self->jsonify(\%ac);
  $ac_json =~ s/\"/\'/g;
  $html .= '<input class="js_param" type="hidden" name="auto_values" value="'.$ac_json.'" />';
  
  
  ## NAVIGATION
  #############
  
  $html .= '<div class="toolbox">';
  $html .= '<div class="toolbox-head">';
  $html .= '<img src="/i/16/eye.png" style="vertical-align:top;"> Navigation<span style="float:right">';
  $html .= $self->helptip("Navigate through the results of your VEP job. By default the results for 5 variants are displayed; note that variants may have more than one result if they overlap multiple transcripts");
  $html .= '</span></div>';
  $html .= "<div style='padding:5px;'>Showing $row_count results";
  $html .= $row_count ? " for variant".($from == $actual_to ? " $from" : "s $from\-$actual_to") : "";
  $html .= $filter_string ? "" : " of $output_lines";
  
  # number of entries
  $html .= ' | <b>Show</b> ';
  
  foreach my $opt_size(qw(1 5 10 50)) {
    next if $opt_size > $output_lines;
    
    if($size eq $opt_size) {
      $html .= " $opt_size";
    }
    else {
      $html .= ' '. $self->reload_link($opt_size, {
        from => $from,
        to   => $to + ($opt_size - $size)
      });
    }
  }
  
  # showing all?
  if(($to - $from) == ($output_lines - 1)) {
    $html .= ' All';
  }
  else {
    my $warning = '';
    if($output_lines > 500) {
      $warning  = '<img class="_ht" src="/i/16/alert.png" style="vertical-align: top;" title="<span style=\'color: yellow; font-weight: bold;\'>WARNING</span>: table with all data may not load in your browser - use Download links instead">';
    }
    
    $html .=  ' ' . $self->reload_link("All$warning", {
      from => 1,
      to   => $output_lines
    });
    
    # navigation
    $html .= ' | ';#<b>Navigation</b> ';
    
    my $style = 'style="vertical-align:top; height:16px; width:16px"';
    my $disabled_style = 'style="vertical-align:top; height:16px; width:16px; opacity: 0.5;"';
    
    # first
    if($from > 1) {
      $html .= $self->reload_link(qq(<img src="/i/nav-l2.gif" $style title="First page"/>), {
        from => 1,
        to   => $size,
      });
    }
    else {
      $html .= '<img src="/i/nav-l2.gif" '.$disabled_style.'/>';
    }
    
    # prev page
    if($from > 1) {
      $html .= $self->reload_link(sprintf('<img src="/i/nav-l1.gif" %s title="Previous %s variant%s"/></a>', $style, $size == 1 ? ('', '') : ($size, 's')), {
        from => $from - $size,
        to   => $to - $size,
      });
    }
    else {
      $html .= '<img src="/i/nav-l1.gif" '.$disabled_style.'/>';
    }
    
    # next page
    if($to <= $actual_to && $to < $output_lines) {
      $html .= $self->reload_link(sprintf('<img src="/i/nav-r1.gif" %s title="Next %s variant%s"/></a>', $style, $size == 1 ? ('', '') : ($size, 's')), {
        from => $from + $size,
        to   => $to + $size,
      });
    }
    else {
      $html .= '<img src="/i/nav-r1.gif" '.$disabled_style.'/>';
    }
    
    # last
    if($to < $output_lines && !$filter_string && !$location) {
      $html .= $self->reload_link(qq(<img src="/i/nav-r2.gif" $style title="Last page"/></a>), {
        from => $size * int($output_lines / $size),
        to   => $output_lines,
      });
    }
    else {
      $html .= '<img src="/i/nav-r2.gif" '.$disabled_style.'/>';
    }
  }
  
  $html .= "</div></div>";
  
  
  ## FILTER
  #########
  
  $html .= '<div class="toolbox">';
  $html .= '<div class="toolbox-head"><img src="/i/16/search.png" style="vertical-align:top;"> Filters<span style="float:right">'.$self->helptip("Filter your results to find interesting or significant data. You can apply several filters on any category of data in your results using a range of operators, add multiple filters, and edit active filters").'</span></div>';
  $html .= '<div style="padding:5px;">';
  
  my $form_url = $hub->url();
  my $ajax_url = $self->ajax_url(undef, {'__clear' => 1});
  
  my $ajax_html .= qq{
    <form action="#" class="_apply_filter" style="margin: 0 0 0 0;">
      <input type="hidden" name="ajax_url" value="$ajax_url" />
  };
  
  # define operators
  my @operators = (
    {name => 'is',  title => 'is'},
    {name => 'ne',  title => 'is not'},
    {name => 're',  title => 'matches'},
    {name => 'lt',  title => '<'},
    {name => 'gt',  title => '>'},
    {name => 'lte', title => '<='},
    {name => 'gte', title => '>='},
  );
  my @non_numerical = @operators[0..2];
  my %operators = map {$_->{name} => $_->{title}} @operators;
  
  # active filters
  my $active_filters = 0;
  my $filter_number;
  
  my @filter_divs;
  my @location_divs;
  
  $html .= '<div>';
  for my $i(1..$max_filters) {
    if($params{"field$i"}) {
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
        $header_titles{$params{"field$i"}} || $params{"field$i"},
        $operators{$params{"operator$i"}},
        $params{"value$i"} || 'defined',
        $i,
        $self->reload_link('<img class="_ht" src="/i/close.png" title="Remove filter" style="height:16px; width:16px">', {
          "field$i"       => undef,
          "operator$i"    => undef,
          "value$i"       => undef,
          'update_panel'  => undef
        })
      );

      # edit filter
      $tmp_html .= '<div class="filter_edit_'.$i.'" style="display:none;">';
      $tmp_html .= $ajax_html;
      
      # field
      $tmp_html .= '<select class="autocomplete" name="field'.$i.'">';
      $tmp_html .= sprintf(
        '<option value="%s" %s>%s</option>',
        $_,
        $_ eq $params{"field$i"} ? 'selected="selected"' : '',
        $header_titles{$_} || $_
      ) for @$headers;
      $tmp_html .= '</select>';
      
      # operator
      $tmp_html .= '<select name="operator'.$i.'">';
      $tmp_html .= sprintf(
        '<option value="%s" %s>%s</option>',
        $_->{name},
        ($_->{name} eq $params{"operator$i"} ? 'selected="selected"' : ''),
        $_->{title}
      ) for @operators;
      $tmp_html .= '</select>';
      
      # value and submit
      $tmp_html .= '<input class="autocomplete" type="text" placeholder="defined" name="value'.$i.'" value="'.$params{"value$i"}.'">';
      $tmp_html .= '<input value="Update" class="fbutton" type="submit">';
      
      # add hidden fields
      $tmp_html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for grep {!/[a-z]$i$/i} keys %params;
      $tmp_html .= '</form>';
      $tmp_html .= '<div style="padding-left: 2px;"><a href="#" class="small filter_toggle" style="color:white;" rel="filter_edit_'.$i.'">Cancel</a></div>';
      $tmp_html .= '</div>';
      
      if($params{"field$i"} =~ /^Location/) {
        push @location_divs, $tmp_html;
      }
      else {
        push @filter_divs, $tmp_html;
      }
    }
    else {
      $filter_number ||= $i;
    }
  }
  
  foreach my $div(@location_divs) {
    $html .= '<div class="location-filter-box filter-box">'.$div.'</div>';
  }
  $html .= '<hr>' if scalar @location_divs && scalar @filter_divs;
  
  foreach my $div(@filter_divs) {
    $html .= '<div class="filter-box">'.$div.'</div>';
  }
  
  $html .= '</div>';
  
  if($active_filters > 1) {
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
  
  $html .= '<hr>' if $active_filters;
  $html .= $ajax_html;
  
  # field
  $html .= '<select class="autocomplete" name="field'.$filter_number.'">';
  $html .= sprintf('<option value="%s">%s</option>', $_, $header_titles{$_} || $_) for @$headers;
  $html .= '</select>';
  
  # operator
  $html .= '<select name="operator'.$filter_number.'">';
  $html .= sprintf('<option value="%s" %s>%s</option>', $_->{name}, ($_->{name} eq 'is' ? 'selected="selected"' : ''), $_->{title}) for @operators;
  $html .= '</select>';
  
  # define numerical fields
  #my %numerical = (
  #  cDNA_position      => 1,
  #  CDS_position       => 1,
  #  Protein_position   => 1,
  #  MOTIF_POS          => 1,
  #  MOTIF_SCORE_CHANGE => 1,
  #  DISTANCE           => 1,
  #  EXON               => 1,
  #  INTRON             => 1,
  #  SIFT               => 1,
  #  PolyPhen           => 1
  #);
  #
  #$html .= '<select name="operator'.$filter_number.'">';
  #foreach my $header(@$headers) {
  #  $html .= sprintf('<option value="%s" class="_stt_%s" %s>%s</option>', $_->{name}, $header, ($_->{name} eq 'is' ? 'selected="selected"' : ''), $_->{title}) for ($numerical{$header} ? @operators : @non_numerical);
  #}
  #$html .= '</select>';
  
  # value and submit
  $html .= '<input class="autocomplete" type="text" placeholder="defined" name="value'.$filter_number.'">';
  $html .= '<input value="Add" class="fbutton" type="submit">';
  
  # add hidden fields
  $html .= sprintf('<input type="hidden" name="%s" value="%s">', $_, $params{$_}) for keys %params;
  $html .= '</form></div>';
  
  
  # presets
  #$html .= '<div style="clear:left;"><div><a rel="filter_presets" class="toggle closed small">Common filter presets</a></div>';
  #$html .= '<div class="filter_presets"><div class="toggleable hidden">';
  #
  #my @presets = (
  #  {
  #    desc => 'Show only novel variants',
  #    url  => 'field22=Existing_variation;operator22=ne;value22='
  #  },
  #  {
  #    desc => 'Select only CCDS protein coding transcripts',
  #    url  => 'field20=CCDS;operator20=is;value20=;field21=BIOTYPE;operator21=is;value21=protein_coding'
  #  },
  #);
  #
  #my $base_url = $self->ajax_url(undef);
  #
  #foreach my $preset(@presets) {
  #  $html .= sprintf(
  #    '<div class="filter-box" style="background-color:white;"><a class="update_panel" rel="%s" href="%s">%s</a></div>',
  #    $panel_id,
  #    $base_url.';'.$preset->{url},
  #    $preset->{desc}
  #  );
  #}
  #
  #$html .= '</ul></div></div>';
  #$html .= '</div>';
  
  $html .= '</div></div>';
  
  
  ## DOWNLOAD
  ###########

  my $dir_loc  = $hub->species_defs->ENSEMBL_TOOLS_TMP_DIR;
  my $file_loc = $output_file_obj->filename =~ s/^$dir_loc\/(temporary|persistent)\/VEP\///r;

  $html .= '<div class="toolbox">';
  $html .= '<div class="toolbox-head"><img src="/i/16/download.png" style="vertical-align:top;"> Download</div><div style="padding:5px;">';

  my $download_url = sprintf('/%s/vep_download?file=%s;name=%s;persistent=%s;prefix=vep', $species, $file_loc, $ticket_name.'.txt', $ticket->owner_type eq 'user' ? 1 : 0);

  # all
  $html .= '<div><b>All</b><span style="float:right; margin-left:10px;">';
  $html .= sprintf(
    ' <a class="_ht" title="Download all results in %s format%s" href="%s;format=%s">%s</a>',
    $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $download_url, lc($_), $_
  ) for qw(VCF VEP TXT);
  $html .= '</span></div>';
  
  # filtered
  if($active_filters) {
    my $filtered_name = $ticket_name.($location ? ' '.$location : '').($filter_string ? ' '.$filter_string : '');
    $filtered_name =~ s/^\s+//g;
    $filtered_name =~ s/\s+/\_/g;
    
    my $filtered_url = sprintf('/%s/vep_download?file=%s;name=%s;persistent=%s;prefix=vep', $species, $file_loc, $filtered_name.'.txt', $ticket->owner_type eq 'user' ? 1 : 0);
    $filtered_url .= ';'.join(";", map {"$_=$content_args{$_}"} grep {!/to|from/} keys %content_args);
    
    $html .= '<div><hr><b>Filtered</b><span style="float:right; margin-left:10px;">';
    $html .= sprintf(
      ' <a class="_ht" title="Download filtered results in %s format%s" href="%s;format=%s">%s</a>',
      $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $filtered_url, lc($_), $_
    ) for qw(VCF VEP TXT);
    $html .= '</span></div>';
  }
  
  
  
  ## BIOMART
  ##########
  
  if($hub->species_defs->ENSEMBL_MART_ENABLED) {
    
    # uniquify lists, retain order
    foreach my $key(keys %seen_ids) {
      my %tmp_seen;
      my @tmp_list;
      
      foreach my $item(@{$seen_ids{$key}}) {
        push @tmp_list, $item unless $tmp_seen{$item};
        $tmp_seen{$item} = 1;
      }
      
      $seen_ids{$key} = \@tmp_list;
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
      $m_species.'_snp.default.filters.snp_filter.%22'.join(",", @{$seen_ids{vars} || []}).'%22'.
      '&VISIBLEPANEL=filterpanel';
    
    my $gene_mart_url =
      '/biomart/martview?VIRTUALSCHEMANAME=default'.
      '&ATTRIBUTES='.
      $m_species.'_gene_ensembl.default.feature_page.ensembl_gene_id|'.
      $m_species.'_gene_ensembl.default.feature_page.chromosome_name|'.
      $m_species.'_gene_ensembl.default.feature_page.start_position|'.
      $m_species.'_gene_ensembl.default.feature_page.end_position'.
      '&FILTERS='.
      $m_species.'_gene_ensembl.default.filters.ensembl_gene_id.%22'.join(",", @{$seen_ids{genes} || []}).'%22'.
      '&VISIBLEPANEL=filterpanel';
    
    $html .= '<div><hr><b>BioMart</b><span style="float:right; margin-left:10px;">';
    
    $html .= $seen_ids{vars} ? sprintf(
      '<a class="_ht" title="Query BioMart with co-located variants in this view" rel="external" href="%s">Variants</a> ',
      $var_mart_url) : 'Variants ';
    
    $html .= $seen_ids{genes} ? sprintf(
      '<a class="_ht" title="Query BioMart with genes in this view" rel="external" href="%s">Genes</a>',
      $gene_mart_url) : 'Genes ';
    
    $html .= '</div>';
  }
  
  $html .= '</div></div>';
  
  # render table
  my $table = $self->new_table(\@table_headers, $rows, { data_table => 1, sorting => [ 'Location asc' ], data_table_config => {bLengthChange => 'false', bFilter => 'false'}, });
  $html .= '<div>'.$table->render.'</div>';
  
  $html .= '</div>';
  
  return $html;
}

sub linkify {
  my $self = shift;
  my $field = shift;
  my $value = shift;
  my $species = shift;
  my $new_value;
  my $hub = $self->hub;
  
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
        type    => 'ZMenu',
        action  => 'Variation',
        v       => $var,
        species => $species
      });
      
      $new_value .= ($new_value ? ', ' : '').sprintf('<a class="zmenu" href="%s">%s</a>', $url, $var);
    }
  }
  
  # transcript
  elsif($field eq 'Feature' && $value =~ /^ENS.{0,3}T\d+$/) {
    my $url = $hub->url({
      type    => 'ZMenu',
      action  => 'Transcript',
      t       => $value,
      species => $species
    });
    
    $new_value = sprintf('<a class="zmenu" href="%s">%s</a>', $url, $value);
  }
  
  # reg feat
  elsif($field eq 'Feature' && $value =~ /^ENS.{0,3}R\d+$/) {
    my $url = $hub->url({
      type    => 'ZMenu',
      action  => 'Regulation',
      rf      => $value,
      species => $species
    });
    
    $new_value = sprintf('<a class="zmenu" href="%s">%s</a>', $url, $value);
  }
  
  # gene
  elsif($field eq 'Gene' && $value =~ /\w+/) {
    my $url = $hub->url({
      type   => 'ZMenu',
      action => 'Gene',
      g      => $value,
      species => $species
    });
    
    $new_value = sprintf('<a class="zmenu" href="%s">%s</a>', $url, $value);
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
    my $var_styles   = $hub->species_defs->colour('variation');
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
  elsif($field =~ /^hgvs/i && $value =~ /\w+/) {
    $new_value = uri_unescape($value);
  }
  
  # CCDS
  elsif($field eq 'CCDS' && $value =~ /\w+/) {
    $new_value = $hub->get_ExtURL_link($value, 'CCDS', $value)
  }
  
  # SIFT/PolyPhen
  elsif($field =~ /sift|polyphen/i && $value =~ /\w+/) {
    my ($pred, $score) = split /\(|\)/, $value;
    $pred =~ s/\_/ /g if $pred;
    $new_value = $self->render_sift_polyphen($pred, $score);
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
    $self->hub->url($url_params, undef, 1),
    $self->ajax_url(undef, $url_params, undef, 1),
    $html
  );
}

1;
