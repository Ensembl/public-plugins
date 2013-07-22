package EnsEMBL::Web::Component::Tools::VEPResults;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);
use EnsEMBL::Web::Form;
use Bio::EnsEMBL::Variation::Utils::VEP qw(@REG_FEAT_TYPES);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self   = shift;
  my $hub    = $self->hub;
  my $object = $self->object;

  return $self->select_ticket('VEP') unless $hub->param('tk');
  
  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  unless ( ref($ticket) ){ 
    my $error = $self->_error('Ticket not found', $ticket, '100%');
    return $self->select_ticket('VEP', $error);
  }

  ## We have a ticket!
  my $html;
  my $name = $ticket->ticket_name;

  my $status = $ticket->status;
  
  my @hive_jobs = @{$ticket->sub_job};

  return '' if $status eq 'Failed';
  
  my $vep_object = $object->deserialise($ticket->analysis->object);
  my $output_file_obj = $vep_object->output_file;
  
  # get job stats
  my $stats = $vep_object->job_statistics;
  my $output_lines = $stats->{'General statistics'}->{'Lines of output written'};
  
  # get all params
  my %params;
  foreach my $p($hub->param) {
    foreach my $v($hub->param($p)) {
      $params{$p} = $v;
    }
  }
  
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
  my $max_filters = 10;
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
          ($params{"value$i"} ne '' ? $params{"operator$i"} : ''),
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
  );
  foreach my $header(grep {/\_/} @$headers) {
    my $tmp = $header;
    $tmp =~ s/\_/ /g;
    $header_titles{$header} = $tmp;
  }
  
  # linkify row content
  foreach my $row(@$rows) {
    $row->{$headers->[$_]} = $self->linkify($headers->[$_], $row->{$headers->[$_]}) for (0..$#{$headers});
  }
  
  # extras
  my %table_sorts = (
    Location => 'hidden_position',
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
  
  my @table_headers = map {{ key => $_, title => $header_titles{$_} || $_, sort => $table_sorts{$_} || 'string'}} @$headers;
  
  
  my $panel_id  = $self->id;
  #$html .= '<link rel="stylesheet" href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css" />';
  $html .= '<link rel="stylesheet" href="/components/ac.css" />';
  $html .= '<div><h3>Results preview</h3>';
  $html .= '<input type="hidden" class="panel_type" value="VEPResults" />';
  
  # construct hash for autocomplete
  my $vdbc = $hub->species_defs->get_config($vep_object->{_species}, 'databases')->{'DATABASE_VARIATION'};
  
  my %ac = (
    Allele => [
      'A', 'C', 'G', 'T'
    ],
    Feature_type => [
      'Transcript', @REG_FEAT_TYPES
    ],
    Consequence => [
      keys %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES
    ],
    SIFT => $vdbc->{'SIFT_VALUES'},
    PolyPhen => $vdbc->{'POLYPHEN_VALUES'},
    BIOTYPE => $hub->species_defs->get_config($vep_object->{_species}, 'databases')->{'DATABASE_CORE'}->{'tables'}{'transcript'}{'biotypes'},
  );
  
  use Data::Dumper;
  $Data::Dumper::Maxdepth = 3;
  warn Dumper $hub->species_defs->get_config($vep_object->{_species}, 'databases')->{'DATABASE_CORE'};
  
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
      my $url = $self->ajax_url(undef, {
        tk   => $name,
        from => $from,
        to   => $to + ($opt_size - $size),
        update_panel => undef,
      });
      $html .= sprintf(' <a href="%s" class="update_panel" rel="%s">%s</a>', $url, $panel_id, $opt_size);
    }
  }
  
  # showing all?
  if(($to - $from) == ($output_lines - 1)) {
    $html .= ' All';
  }
  else {
    my $url = $self->ajax_url(undef, {
      tk   => $name,
      from => 1,
      to   => $output_lines
    }, undef, 1);
    
    
    my $warning = '';
    if($output_lines > 500) {
      $warning  = '<img class="_ht" src="/i/16/alert.png" style="vertical-align: top;" title="<span style=\'color: yellow; font-weight: bold;\'>WARNING</span>: table with all data may not load in your browser - use Download links instead">';
    }
    
    $html .=  sprintf(' <a class="update_panel" rel="%s" href="%s">All%s</a>', $panel_id, $url, $warning);
    
    # navigation
    $html .= ' | ';#<b>Navigation</b> ';
    
    my $style = 'style="vertical-align:top; height:16px; width:16px"';
    my $disabled_style = 'style="vertical-align:top; height:16px; width:16px; opacity: 0.5;"';
    
    # first
    if($from > 1) {
      my $url = $self->ajax_url(undef, {
        tk   => $name,
        from => 1,
        to   => $size,
      }, undef, 1);
      $html .= sprintf(
        '<a class="update_panel _ht" rel="%s" href="%s"><img src="/i/nav-l2.gif" %s title="First page"/></a>',
        $panel_id, $url, $style
      );
    }
    else {
      $html .= '<img src="/i/nav-l2.gif" '.$disabled_style.'/>';
    }
    
    # prev page
    if($from > 1) {
      my $url = $self->ajax_url(undef, {
        tk   => $name,
        from => $from - $size,
        to   => $to - $size,
      }, undef, 1);
      $html .= sprintf(
        '<a class="update_panel _ht" rel="%s" href="%s"><img src="/i/nav-l1.gif" %s title="Previous %s variants"/></a>',
        $panel_id, $url, $style, $size
      );
    }
    else {
      $html .= '<img src="/i/nav-l1.gif" '.$disabled_style.'/>';
    }
    
    # next page
    if($to <= $actual_to && $to < $output_lines) {
      my $url = $self->ajax_url(undef, {
        tk   => $name,
        from => $from + $size,
        to   => $to + $size,
      }, undef, 1);
      $html .= sprintf(
        '<a class="update_panel _ht" rel="%s" href="%s"><img src="/i/nav-r1.gif" %s title="Next %s variants"/></a>',
        $panel_id, $url, $style, $size
      );
    }
    else {
      $html .= '<img src="/i/nav-r1.gif" '.$disabled_style.'/>';
    }
    
    # last
    if($to < $output_lines && !$filter_string && !$location) {
      my $url = $self->ajax_url(undef, {
        tk   => $name,
        from => $size * int($output_lines / $size),
        to   => $output_lines,
      }, undef, 1);
      $html .= sprintf(
        '<a class="update_panel _ht" rel="%s" href="%s"><img src="/i/nav-r2.gif" %s title="Last page"/></a>',
        $panel_id, $url, $style
      );
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
    <form action="#" class="update_panel" style="margin: 0 0 0 0;">
      <input type="hidden" name="panel_id" value="$panel_id" />
      <input type="hidden" name="url" value="$ajax_url" />
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
      
      my $remove_url = $self->ajax_url(undef, {"field$i" => undef, "operator$i" => undef, "value$i" => undef});
      #$remove_url .= sprintf('&%s=%s', $_, $params{$_}) for grep {!/(field|operator|value)$i/} keys %params;
      
      # filter display
      $tmp_html .= sprintf(qq{
        <div class="filter filter_edit_%s">
          %s %s %s
          <span style="float:right; vertical-align: top;">
            <a href="#" class="filter_toggle" rel="filter_edit_%s"><img class="_ht" src="/i/16/pencil-whitebg.png" title="Edit filter"></a>
            <a class="update_panel" rel="%s" href="%s"><img class="_ht" src="/i/close.png" title="Remove filter" style="height:16px; width:16px"></a>
          </span>
        </div>},
        $i,
        $header_titles{$params{"field$i"}} || $params{"field$i"},
        $operators{$params{"operator$i"}},
        $params{"value$i"} || 'defined',
        $i,
        $panel_id,
        $remove_url,
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
      $tmp_html .= '<input value="Edit" class="fbutton" type="submit">';
      
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
    
    if(scalar @filter_divs) {
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
  
  $html .= '</div></div>';
  
  
  ## DOWNLOAD
  ###########
  
  $html .= '<div class="toolbox">';
  $html .= '<div class="toolbox-head"><img src="/i/16/download.png" style="vertical-align:top;"> Download</div><div style="padding:5px;">';
  
  my $download_url = sprintf('/%s/vep_download?file=%s;name=%s;prefix=vep', $hub->species, $output_file_obj->filename, $name.'.txt');
  
  # all
  $html .= '<div><b>All</b><span style="float:right; margin-left:10px;">';
  $html .= sprintf(
    ' <a class="_ht" title="Download all results in %s format%s" href="%s;format=%s">%s</a>',
    $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $download_url, lc($_), $_
  ) for qw(VCF VEP TXT);
  $html .= '</span></div>';
  
  # filtered
  if($active_filters) {
    my $filtered_name = $name.($location ? ' '.$location : '').($filter_string ? ' '.$filter_string : '');
    $filtered_name =~ s/^\s+//g;
    $filtered_name =~ s/\s+/\_/g;
    
    my $filtered_url = sprintf('/%s/vep_download?file=%s;name=%s;prefix=vep', $hub->species, $output_file_obj->filename, $filtered_name.'.txt');
    $filtered_url .= ';'.join(";", map {"$_=$content_args{$_}"} grep {!/to|from/} keys %content_args);
    
    $html .= '<div><hr><b>Filtered</b><span style="float:right; margin-left:10px;">';
    $html .= sprintf(
      ' <a class="_ht" title="Download filtered results in %s format%s" href="%s;format=%s">%s</a>',
      $_, ($_ eq 'TXT' ? ' (best for Excel)' : ''), $filtered_url, lc($_), $_
    ) for qw(VCF VEP TXT);
    $html .= '</span></div>';
  }
  
  $html .= '</div></div>';
  
  # render table
  my $table = $self->new_table(\@table_headers, $rows, { data_table => 1, data_table_config => {bLengthChange => 'false', bFilter => 'false'}, });
  $html .= '<div>'.$table->render.'</div>';
  
  $html .= '</div>';
  
  return $html;
}

sub linkify {
  my $self = shift;
  my $field = shift;
  my $value = shift;
  my $new_value;
  my $hub = $self->hub;
  
  $value =~ s/\,/\, /g;
  
  # location
  if($field eq 'Location') {
    my $url = $hub->url({
      type             => 'Location',
      action           => 'View',
      r                => $value,
      contigviewbottom => "variation_feature_variation=normal",
    });
    
    $new_value = sprintf('<a class="_ht" title="View in location tab" href="%s">%s</a>', $url, $value);
  }
  
  # existing variation
  elsif($field eq 'Existing_variation' && $value =~ /\w+/) {
    
    foreach my $var(split /\,\s*/, $value) {
      my $url = $hub->url({
        type => 'ZMenu',
        action => 'Variation',
        v => $var,
      });
      
      $new_value .= ($new_value ? ', ' : '').sprintf('<a class="zmenu" href="%s">%s</a>', $url, $var);
    }
  }
  
  # transcript
  elsif($field eq 'Feature' && $value =~ /^ENS.{0,3}T\d+$/) {
    my $url = $hub->url({
      type => 'ZMenu',
      action => 'Transcript',
      t => $value
    });
    
    $new_value = sprintf('<a class="zmenu" href="%s">%s</a>', $url, $value);
  }
  
  # reg feat
  elsif($field eq 'Feature' && $value =~ /^ENS.{0,3}R\d+$/) {
    my $url = $hub->url({
      type => 'ZMenu',
      action => 'Regulation',
      rf => $value
    });
    
    $new_value = sprintf('<a class="zmenu" href="%s">%s</a>', $url, $value);
  }
  
  # gene
  elsif($field eq 'Gene' && $value =~ /\w+/) {
    my $url = $hub->url({
      type => 'ZMenu',
      action => 'Gene',
      g => $value
    });
    
    $new_value = sprintf('<a class="zmenu" href="%s">%s</a>', $url, $value);
  }
  
  # consequence type
  elsif($field eq 'Consequence' && $value =~ /\w+/) {
    my $cons = \%Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;
    my $var_styles   = $hub->species_defs->colour('variation');
    my $colourmap    = $hub->colourmap;
    
    foreach my $con(split /\,\s+/, $value) {
      $new_value .= $new_value ? ', ' : '';
      
      if(defined($cons->{$con})) {
        my $colour = $colourmap->hex_by_name($var_styles->{$con}->{'default'}) if defined $var_styles->{$con};
        $colour  ||= 'no_colour';
        
        $new_value .=
          sprintf(
            '<nobr><span class="colour" style="background-color:%s">&nbsp;</span> '.
            '<span style="border-bottom:1px dotted #999; cursor: help;" class="_ht" title="%s">%s</span></nobr>',
            $colour, $cons->{$con}->description, $con
          );
      }
      else {
        $new_value .= $con;
      }
    }
  }
  
  else {
    $new_value = defined($value) && $value ne '' ? $value : '-';
  }
  
  return $new_value;
}

1;
