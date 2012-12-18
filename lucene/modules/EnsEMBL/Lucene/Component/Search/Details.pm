package EnsEMBL::Lucene::Component::Search::Details;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Search);

use Lingua::EN::Inflect qw(PL NUM);
use URI::Escape;
use Encode qw(encode);
use EnsEMBL::Web::Document::HTML::HomeSearch;
use EnsEMBL::Web::Component::Help::Faq;

sub content {
  my $self = shift;

  my $html;

  if ($self->hub->param('q')) {
    $html = $self->render_summary;
    $html .= $self->render_pagination;
    $html .= $self->render_hits;
    $html .= $self->render_pagination;
  }
  else {
    my $search = EnsEMBL::Web::Document::HTML::HomeSearch->new($self->hub);
    $html = $search->render;
  }
  return $html;
}

sub _format_message {
  my ( $self, $idx, $count, $query, $species ) = @_;
  $idx =~ s/^\w+_(.*)/\u$1/;
  $idx .= " Document" if $idx =~ /Glossary|Help/;
  $idx = 'Document' if $idx eq 'Docs';
  $idx = uc($idx) if $idx eq 'Faq';
  $idx = 'Somatic Mutation' if $idx eq 'Mutation';
  my $message = NUM( $count, 'true' ) . ' ' . PL($idx) . ' ' . PL('matches') . " your query ('$query')";
  $message =~ s/Variationses/Variations/g; #hack for Structural Variations

  my $display_species = $species eq 'all' ? 'all species' : $self->hub->species_defs->get_config($species,'SPECIES_COMMON_NAME');
  #uncomment this to show latin name as well
#  $species =~ s/_/ /g;
#  $display_species .= " ($species).";
  $message .= " in $display_species" if $display_species;
  return $message;
}


sub render_summary {
  my $self = shift;
  my $hub = $self->hub;

  my $species = $hub->param('species') || $self->species;
  my $species_searched  = $species unless $species eq 'all';
  my $search_term       = $hub->param('q');

  my $total_entries = $self->object->nhits;

  if ( $total_entries > 0 ) {
    my $idx = $hub->param('idx');

    my $summary_message =
      qq{<h3 id="search_summary_message">}
      . $self->_format_message( $idx, $total_entries, $search_term, $species_searched)
      . qq{</h3>};

    if ( $total_entries > 10 ) {
      my $pager              = $self->object->pager || warn "No pager found in the Search Object";
      my $page_first_hit     = $pager->first;
      my $page_last_hit      = $pager->last;
      $summary_message .= (
         qq{<p>Showing results <strong>$page_first_hit-$page_last_hit</strong></p>}
        ) . ( $page_last_hit >= 10000 ? qq{<p class="small">Results beyond 10000 not shown.</p>} : '' );

    }
    return $summary_message;
  }
  else {
    return $self->no_results($search_term);
  }
}

sub render_pagination {
  my $self = shift;
  return if $self->object->nhits < 11;

  my $species        = $self->hub->param('species') || 'all';
  my $search_term    = $self->hub->param('q');
  my $idx            = $self->hub->param('idx');
  my $end            = $self->hub->param('end');
  my $pagination_uri = sprintf( "q=%s;species=%s;end=%s;idx=%s;", $search_term, $species, $end, $idx );

  my $pager         = $self->object->pager; 
  return unless $pager;
  my $last_page     = $pager->last_page;
  my $previous_page = $pager->previous_page;
  my $next_page     = $pager->next_page;
  my $current_page  = $pager->current_page;

  my $out = '<div class="paginate">';

  if ($previous_page) {
    $out .= sprintf( '<a class="prev" href="?page=%s;%s">&laquo; Prev</a> ', $previous_page, $pagination_uri );
  }
  else {
    $out .= '<a class="prev nav_el_hidden" href="">&laquo; Prev></a>';
  }
  foreach my $i ( 1 .. $last_page ) {
    if ( $i == $current_page ) {
      $out .= sprintf( '<span class="current">%s</span> ', $i );
    }
    elsif ($i < 5
          || ( $last_page - $i ) < 4
          || abs( $i - $current_page + 1 ) < 4 )
      {
      $out .= sprintf( '<a href="?page=%s;%s">%s</a>', $i, $pagination_uri, $i );
    }
    else {
      $out .= '..';
    }
  }
  $out =~ s/\.\.+/ &hellip; /g;
  if ($next_page) {
    $out .= sprintf( '<a class="next" href="?page=%s;%s">Next &raquo;</a> ', $next_page, $pagination_uri );
  }
  else {
    $out .= '<a class="next nav_el_hidden" href="">Next &raquo;</a>';
  }
  return qq{$out</div><div class="clear"></div>};
}

sub render_hits {
  my $self = shift;
  my $hits = $self->object->hits;
  my %hit_tagline_lookup = (
    'GENE' => sub {
      return qq{<strong>$_[0]->{name}</strong> };
    },
    'TRANSCRIPT' => sub {
      return qq{<strong>$_[0]->{name}</strong> };
    },
    'IDHISTORY_GENE'        => sub { return "Archived Gene Stable ID: $_[0]->{id}" },
    'IDHISTORY_TRANSCRIPT'  => sub { return "Archived Transcript Stable ID: $_[0]->{id}" },
    'IDHISTORY_TRANSLATION' => sub { return "Archived Translation Stable ID: $_[0]->{id}" },
    'FAMILY'                => sub { return "Ensembl protein family: $_[0]->{id}" },
    'DOMAIN'                => sub { return "Interpro domain: $_[0]->{id}" },
    'VARIATION'             => sub { return "$_[0]->{id}" },
    'SEQUENCE'              => sub { return ( $_[0]->{id} =~ /LRG/ ? 'LRG' : '' ) . " Sequence: $_[0]->{id}" },
    'PROTEINALIGNFEATURE' => sub { return "Protein alignment feature : @{[$_[0]->{description} =~ /(^.*)\shits/]}" },
    'DNAALIGNFEATURE'     => sub { return "DNA alignment feature : @{[$_[0]->{description} =~ /(^.*)\shits/]}" },
    'PHENOTYPE'           => sub { return "Phenotype: $_[0]->{description}" },
    'STRUCTURALVARIATION' => sub { return "Structural Variation: $_[0]->{id}" },
    'MARKER'              => sub { return "Marker: $_[0]->{id}" },
    'REGULATORYFEATURE'   => sub { return ($_[0]->{subtype} eq 'RegulatoryFactor') ? "Regulatory region: $_[0]->{id}" : "Regulatory Feature: $_[0]->{id}"},
    'QTL'                 => sub { return "QTL: $_[0]->{id}" },
    'PROBEFEATURE'        => sub { return "Probe: $_[0]->{id}" },
  );
  my $html = '<div class="searchresults">';
  $html .=
        $hits->[0]->{featuretype} =~ /Glossary|FAQ|View/i || !$hits->[0]->{featuretype}
      ? $self->_render_help_results( $hits, \%hit_tagline_lookup )
      : $self->_render_genome_hits( $hits, \%hit_tagline_lookup );
  $html .= "</div> <!-- end searchresults -->";
  return $html;
}

sub _render_help_results {
  my ( $self, $hits, $hit_tagline_lookup ) = @_;
  my $html;
  my $search_term = $self->hub->param('q');
  foreach my $hit (@$hits) {
    $html .= qq{<div class="hit">};

    my $title = $hit->{title};

    my $display_identifier = $hit->{featuretype} eq 'Phenotype' ? $hit->{description} : $hit->{id};

#    my $url                = $hit->{featuretype} =~ /Glossary|FAQ|View/ ?  $hit->{feature_url} : $hit->{feature_url};
    my $url = $hit->{feature_url} || $hit->{url};

    $url =~ s{http://.*?/}{};

    my $species = $hit->{species};

    my $hit_tagline = $hit->{title} || $hit->{displayname};

    unless ($hit_tagline) {
      if ($url =~ /pdf$/) {
        ($hit_tagline) = $url =~ /\/(\w+.pdf)$/;
        $hit_tagline ||= 'PDF download';
      }
      else {
        $hit_tagline = $url;
      }
    }

    $html .= sprintf qq{<div class="header"><a class="notext%s" href="/$url">$hit_tagline</a></div>}, $hit->{'featuretype'} =~ /^(FAQ|Glossary|View)$/ ? ' popup' : '';

    my $species_no_underscore;
    ( $species_no_underscore = $species ) =~ s/_/ /;

    my $featuretype = $hit->{featuretype};
    my $content = encode( "utf8", $hit->{content} ) || $hit->{description};
    
    $content =~ s/&nbsp;/ /g;
    $content =~ s/\n(?=\s)//g;
    my @content_words = split /\b/, $content;

    # warn "FOUND ". scalar @content_words;
    my $i;
    my $context_content;
    foreach my $word (@content_words) {
      $i++;

      # warn $word;
#      $context_content = $hit->{keyword};
      next if $word !~ /$search_term/i;

      # warn "MATCHED at $i", @content_words[$i-40 .. $i + 40] ;
      $context_content = '... ' . join('', map $content_words[$_], $i-40..$i+40) . ' ...';
      last;
    }
    unless ($context_content) {
      $context_content = join('', map $content_words[$_], 0..80) . ' ...';
    }
    $context_content =~ s/($search_term)/<strong>$1<\/strong>/ig;

    # $content = encode("utf8", $context_content);
    my $db_extra = $hit->{'db'} ? ';db=' . $hit->{'db'} : '';
    $html .= qq{<p>$context_content</p>};

    ## DOES STATIC CONTENT EVER HAVE A LOCATION & FEATURE?
    if ($hit->{location} && $hit->{featuretype} eq 'Gene') {
      $html .= $self->new_twocol(['Location', qq(<p><a href="/$hit->{species}/Location/View?r=$hit->{location};g=$hit->{id}$db_extra">$hit->{location}</a></p>), 1])->render;
    }
    $html .= "</div> <!-- end hit -->";
  }
  return $html;
}


sub _render_genome_hits {
  my ( $self, $hits, $hit_tagline_lookup ) = @_;
  my $hub             = $self->hub;
  my $search_term     = $hub->param('q');
  my $species_defs    = $hub->species_defs;
  my $sitetype        = $species_defs->ENSEMBL_SEARCHTYPE ? lc $species_defs->ENSEMBL_SEARCHTYPE : lc($species_defs->ENSEMBL_SITETYPE);
  my $prefix          = $sitetype eq 'vega' ? 'v' :  $sitetype eq 'pre' ? 'pre' : 'e';
  my $ensembl_version = $prefix . $species_defs->ENSEMBL_VERSION;
  my $html;

  foreach my $hit (@$hits) {
    my $sv_evidence; #if the hit contains an evidence term then use it to add a link
    if ($hit->{'featuretype'} eq 'StructuralVariation') {
      ($sv_evidence) = grep {$_ eq $search_term } split '\n', $hit->{'evidence'};
    }

    $html .= qq{<div class="hit">};
    my $table = $self->new_twocol;

    my $id                 = $hit->{id};
    my $display_identifier = $hit->{featuretype} eq 'Phenotype' ? $hit->{description} : $hit->{id};
    my $url                = $hit->{feature_url};
    my $species = $hit->{species};

    my $hit_tagline = eval { $hit_tagline_lookup->{ uc $hit->{featuretype} }($hit) } || '';
    $hit_tagline =~ s/\[/ [/;

    $html .= qq{<div class="header"><a class="notext" href="/$url">$hit_tagline</a></div>};

    my $species_no_underscore;
    ( $species_no_underscore = $species ) =~ s/_/ /;

    my $featuretype = $hit->{featuretype};
    my $description = $hit->{description};
    my $db_extra    = $hit->{'db'} ? ';db=' . $hit->{'db'} : '';
    $table->add_row('Description', $description);

    if ($hit->{featuretype} =~ /Gene|Transcript/) {
      my $label = $hit->{featuretype} eq 'Gene' ? 'Gene ID' : 'Transcript ID';
      my $url = $hit->{featuretype} eq 'Gene' ? "/$hit->{species}/Gene/Summary?g=$hit->{id}$db_extra"
               : "/$hit->{species}/Transcript/Summary?t=$hit->{id}$db_extra";
      $table->add_row($label, qq(<p><a href="$url">$hit->{id}</a></p>));
    }

    if ($hit->{featuretype} =~ /Variation/) {
      my $label = 'Variation ID';
      $table->add_row($label, qq(<p><a href="/$url">$hit->{id}</a></p>));

      #show some context for Variations
      if ($hit->{location}) {
        my @location_links;
        for (split "\n", $hit->{location}) {

          my ($chr,$loc,$strand) = split ':',$_;
          my ($start,$end)       = split '-',$loc;
          my $hit_location_label = $start-$end ? "$chr:$start-$end" : "$chr:$start";
          my $context = 50;
          if ($end < $start) {
            $start += $context;
            $end   -= $context;
          }
          else {
            $start -= $context;
            $end   += $context;
          }

          my $v_param = $hit->{featuretype} eq 'StructuralVariation' ? 'sv' : 'v';

          push @location_links, sprintf(qq(<a href="%s$db_extra">$hit_location_label</a>), $hub->url({
            'species' => $hit->{'species'},
            'type'    => 'Location',
            'action'  => 'View',
            'r'       => $chr && $start && $end && $strand ? "$chr:$start-$end:$strand" : $_,
            $v_param  => $hit->{'id'}
          }));
        }
        $table->add_row($self->append_s_to_plural('Location', @location_links > 1), sprintf('<p>%s</p>', join(', ', @location_links)));
      }

      if ($sv_evidence) {
        $table->add_row('Supporting Evidence', qq(<p><a href="/$hit->{species}/StructuralVariation/Evidence?sv=$hit->{id}">$sv_evidence</a> is a supporting evidence for $hit->{id}</p>));
      }
    }
    elsif ($hit->{location}) {
      $table->add_row('Location', qq(<p><a href="/$hit->{species}/Location/View?r=$hit->{location};g=$hit->{id}$db_extra">$hit->{location}</a></p>));
    }

    if ($species_defs->databases->{'DATABASE_VARIATION'} && $hit->{featuretype} =~ /Gene/) {
      $table->add_row('Variations', qq(<p><a href="/$hit->{species}/Gene/Variation_Gene/Table?g=$hit->{id}">Variation Table</a></p>));
    }

    $table->add_row('Source', $ensembl_version);

    $html .= $table->render."</div> <!-- end hit -->";

  }
  return $html;
}

1;

