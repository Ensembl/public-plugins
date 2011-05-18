package EnsEMBL::Lucene::Component::Search::Details;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);

use Lingua::EN::Inflect qw(PL NUM);
use URI::Escape;
use Encode qw(encode);

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
  my $message = NUM( $count, 'true' ) . ' ' . PL($idx) . ' ' . PL('matches') . " your query ('$query')";
  $message .= " in $species" if $species;
  return $message;
}


sub render_summary {
  my $self = shift;
  my $hub = $self->hub;

  my $species = $hub->param('species') || $self->species;
  $species =~ s/_/ /g;

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
         qq{<p class="space-below">Showing results <strong>$page_first_hit-$page_last_hit</strong></p>}
        ) . ( $page_last_hit >= 10000 ? qq{<p class="small space-below">Results beyond 10000 not shown.</p>} : '' );

    }
    return $summary_message;
  }
  else {
    return
     qq{<p>Your query <strong>- $search_term  -</strong> did not match any records in the database. Please make sure all terms are spelled correctly</p>};
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
      return qq{<strong>$_[0]->{name}</strong><span class="small">[ $_[0]->{source}: $_[0]->{id} ]</span> };
    },
    'TRANSCRIPT' => sub {
      return qq{<strong>$_[0]->{name}</strong><span class="small">[ $_[0]->{source}: $_[0]->{id} ]</span> };
    },
    'IDHISTORY_GENE'        => sub { return "Archived Gene Stable ID: $_[0]->{id}" },
    'IDHISTORY_TRANSCRIPT'  => sub { return "Archived Transcript Stable ID: $_[0]->{id}" },
    'IDHISTORY_TRANSLATION' => sub { return "Archived Translation Stable ID: $_[0]->{id}" },
    'FAMILY'                => sub { return "Ensembl protein family: $_[0]->{id}" },
    'DOMAIN'                => sub { return "Interpro domain: $_[0]->{id}" },
    'VARIATION'             => sub { return "$_[0]->{source} Variation: $_[0]->{id}" },
    'SEQUENCE'              => sub { return ( $_[0]->{id} =~ /LRG/ ? 'LRG' : '' ) . " Sequence: $_[0]->{id}" },
    'PROTEINALIGNFEATURE' => sub { return "Protein alignment feature : @{[$_[0]->{description} =~ /(^.*)\shits/]}" },
    'DNAALIGNFEATURE'     => sub { return "DNA alignment feature : @{[$_[0]->{description} =~ /(^.*)\shits/]}" },
    'PHENOTYPE'           => sub { return "SNPPhenotype: $_[0]->{description}" },
    'STRUCTURALVARIATION' => sub { return "Structural Variation: $_[0]->{id}" },
    'MARKER'              => sub { return "Ensembl Marker: $_[0]->{id}" },
    'REGULATORYFEATURE'   => sub { return "RNA: $_[0]->{id}" },
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

    $html .=
      qq{<div style="width: 85%;border-bottom: 1px solid #CCCCCC; "><a class="notext" href="/$url">$hit_tagline</a></div>};

    my $species_no_underscore;
    ( $species_no_underscore = $species ) =~ s/_/ /;

    my $featuretype = $hit->{featuretype};
    my $content = encode( "utf8", $hit->{content} ) || $hit->{description};

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
      $context_content = "... @content_words[$i-40 .. $i + 40] ...";
      last;
    }
    unless ($context_content) {
      $context_content = "@content_words[0 .. 80] ...";
    }
    $context_content =~ s/($search_term)/<strong>$1<\/strong>/g;

    # $content = encode("utf8", $context_content);
    my $db_extra = $hit->{'db'} ? ';db=' . $hit->{'db'} : '';
    $html .= qq{
<dl class="summary">
  <dt>&nbsp;</dt>
  <dd>$context_content</dd>
</dl>
    };

    if ($hit->{location} && $hit->{featuretype} eq 'Gene') {
      $html .= qq{
<dl class="summary">
  <dt>Location</dt>
  <dd><a href="/$hit->{species}/Location/View?r=$hit->{location};g=$hit->{id}$db_extra">$hit->{location}</a></dd>
</dl>
      };
    }
    $html .= "</div> <!-- end hit -->";
  }
  return $html;
}


sub _render_genome_hits {
  my ( $self, $hits, $hit_tagline_lookup ) = @_;
  my $ensembl_version = 'e' . $self->hub->species_defs->ENSEMBL_VERSION;
  my $html;

  foreach my $hit (@$hits) {
    $html .= qq{<div class="hit">};

    my $id                 = $hit->{id};
    my $display_identifier = $hit->{featuretype} eq 'Phenotype' ? $hit->{description} : $hit->{id};
    my $url                = $hit->{feature_url};

    my $species = $hit->{species};

    my $hit_tagline = eval { $hit_tagline_lookup->{ uc $hit->{featuretype} }($hit) } || '';
    $hit_tagline =~ s/\[/ [/;

    $html .=
qq{<div style="width: 85%;border-bottom: 1px solid #CCCCCC; "><a class="notext" href="/$url">$hit_tagline</a></div>};

    my $species_no_underscore;
    ( $species_no_underscore = $species ) =~ s/_/ /;

    my $featuretype = $hit->{featuretype};
    my $description = $hit->{description};
    my $db_extra    = $hit->{'db'} ? ';db=' . $hit->{'db'} : '';
    $html .= qq(   
<dl class="summary">
  <dt>Description</dt>
  <dd>$description</dd>
</dl>
);
    If ($hit->{location} && $hit->{featuretype} =~ /Gene|Transcript|Variation/) {
      $html .= qq(
<dl class="summary">
  <dt>Location</dt>
  <dd><a href="/$hit->{species}/Location/View?r=$hit->{location};g=$hit->{id}$db_extra">$hit->{location}</a></dd>
</dl>
);
    }

    $html .= qq(                      
<dl class="summary">
  <dt>Source</dt>
  <dd>$ensembl_version</dd>
</dl>
);

    $html .= "</div> <!-- end hit -->";

  }
  return $html;
}



1;

