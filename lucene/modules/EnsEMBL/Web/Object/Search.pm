package EnsEMBL::Web::Object::Search;

### NAME: EnsEMBL::Web::Object::Search
### A container for Lucene::WSWrapper, used by search results pages 

### PLUGGABLE: Yes, using Proxy::Object 

### STATUS: At Risk
### Has no data access functionality, just page settings

### DESCRIPTION


use strict;

use base qw(EnsEMBL::Web::Object);

use Data::Page;

use List::MoreUtils qw(any);

sub default_action { return 'New'; }

sub short_caption  {
  my ($self, $search_type) = @_;
  my $sitetype = $self->hub->species_defs->ENSEMBL_SITETYPE || 'Ensembl';
  return $search_type eq 'global' ? 'New Search' : "Search $sitetype";
}

sub caption {
  my $self = shift; 
  my $sitetype = $self->hub->species_defs->ENSEMBL_SITETYPE || 'Ensembl';
  return "$sitetype Lucene search";
}

### Accessors for extra data fields produced by the web search

sub hits    { my ($self, $h) = @_; $self->{'data'}{'hits'} = $h if $h;   return $self->{'data'}{'hits'}; }
sub nhits   { my ($self, $h) = @_; $self->{'data'}{'nhits'} = $h if $h;  return $self->{'data'}{'nhits'}; }
sub query   { my ($self, $q) = @_; $self->{'data'}{'query'} = $q if $q;  return $self->{'data'}{'query'}; }
sub groups  { my ($self, $g) = @_; $self->{'data'}{'groups'} = $g if $g; return $self->{'data'}{'groups'}; }
sub pager   { my ($self, $p) = @_; $self->{'data'}{'pager'} = $p if $p;  return $self->{'data'}{'pager'}; }
sub __status  { my ($self, $s) = @_; $self->{'data'}{'__status'} = $s if $s; return $self->{'data'}{'__status'}; }
sub __error   { my ($self, $e) = @_; $self->{'data'}{'__error'} = $e if $e;  return $self->{'data'}{'__error'}; }

sub specific_query_string { $_[0]->{'data'}{'specific_qs'} ||= $_[1]; }
sub general_query_string { $_[0]->{'data'}{'general_qs'} ||= $_[1]; }

sub feature2url {
  my ( $self, $hit ) = @_;

  my %lookup = (
    'MARKER' => sub { return "$_[0]->{species}/Marker/Details?m=$_[0]->{id};contigviewbottom=marker_core_marker;toggle_tracks=1" },
    'DOMAIN' => sub { return "$_[0]->{species}/Location/Genome/?ftype=$_[0]->{featuretype};id=$_[0]->{id}" },
    'FAMILY' => sub { return "$_[0]->{species}/Gene/Family/Genes?family=$_[0]->{id}" },
    'GENOMICALIGNMENT' => sub {
      return "$_[0]->{species_path}/Location/Genome?ftype=$_[0]->{Source};id=$_[0]->{id}"
        . ( $_[0]->{db} ? '' : ";db=$_[0]->{db}" );
      },  
    'OLIGOPROBE' => sub { return "$_[0]->{species_path}/Location/Genome?ftype=OligoProbe;id=$_[0]->{id}" },
    'QTL'        => sub { return "$_[0]->{species_path}/contigview/l&%s" },
    'GENOMIC'    => sub {
      return 
        "$_[0]->{species_path}/Location/"
          . ( $_[0]->{length} > 0.5e6 ? 'View' : 'Overview' )
          . "?mapfrag=$_[0]->{Name}";
      },
    'SNP'       => sub { return "$_[0]->{species}/Variation/Summary?v=$_[0]->{id};source=$_[0]->{source}" },
    'VARIATION' => sub { return "$_[0]->{species}/Variation/Summary?v=$_[0]->{id};source=$_[0]->{source}" },
    'GENE' =>
      sub { return "$_[0]->{species}/Gene/Summary?g=$_[0]->{id}" . ( $_[0]->{db} ? ";db=$_[0]->{db}" : '' ) },
    'TRANSCRIPT' =>
      sub { return "$_[0]->{species}/Transcript/Summary?t=$_[0]->{id}" . ( $_[0]->{db} ? ";db=$_[0]->{db}" : '' ) },
    'IDHISTORY_GENE'        => sub { return "$_[0]->{species}/Gene/Idhistory?g=$_[0]->{id}" },
    'IDHISTORY_TRANSCRIPT'  => sub { return "$_[0]->{species}/Transcript/Idhistory?t=$_[0]->{id}" },
    'IDHISTORY_TRANSLATION' => sub { return "$_[0]->{species}/Transcript/Idhistory?protein=$_[0]->{id}" },
    'QTL'                   => sub { return "$_[0]->{species}/Location/View?r=$_[0]->{location}" },
    'UNMAPPEDFEATURE'       => sub { return "$_[0]->{species_path}/Location/Genome?ftype=Gene;id=$_[0]->{id}" },
    'PROBEFEATURE'          => sub {
      return "$_[0]->{species}/Location/Genome?ftype=ProbeFeature;fdb=funcgen;id=$_[0]->{id};ptype="
        . ( $_[0]->{description} =~ /set/ ? "pset;" : "probe;" );
    },
    'PROTEINALIGNFEATURE' => sub {
      return
        "$_[0]->{species}/Location/Genome?ftype=$_[0]->{featuretype};id=$_[0]->{id}"
          . ( $_[0]->{db} ? ";db=$_[0]->{db}" : '' )
          . ( $_[0]->{contigviewbottom} ? ";contigviewbottom=$_[0]->{contigviewbottom};toggle_tracks=1" : '' );
      },
    'DNAALIGNFEATURE' => sub {
      return
        "$_[0]->{species}/Location/Genome?ftype=DnaAlignFeature;id=$_[0]->{id}"
          . ( $_[0]->{db} ? ";db=$_[0]->{db}" : '' )
          . ( $_[0]->{contigviewbottom} ? ";contigviewbottom=$_[0]->{contigviewbottom};toggle_tracks=1" : '' );
      },
    'PHENOTYPE' => sub {
      return
          "$_[0]->{species}/Phenotype/Locations?ph=$_[0]->{id}";
      },
    'SEQUENCE' => sub {
      return $_[0]->{id} =~ /^LRG/
        ? "$_[0]->{species}/LRG/Summary?lrg=$_[0]->{id}"
        : "$_[0]->{species}/Location/View?r=$_[0]->{location}";
      },
    'STRUCTURALVARIATION' => sub { return "$_[0]->{species}/StructuralVariation/Summary?sv=$_[0]->{id}" },
    'REGULATORYFEATURE'   => sub {
      return $_[0]->{id} =~ /ENSR|ENSMUSR/
        ? "$_[0]->{species}/Regulation/Cell_line?rf=$_[0]->{id}"
        : "$_[0]->{species}/Location/Genome?ftype=RegulatoryFactor;id=$_[0]->{id};fset=$_[0]->{subtype}";
    },
    'FAQ'      => sub { return "Help/Faq?id=$_[0]->{id}" },
    'GLOSSARY' => sub { return "Help/Glossary?id=$_[0]->{id}" },
    'VIEW'     => sub { return "Help/View?id=$_[0]->{id}" },
  );

  $hit->{species} =~ s/ /_/g;
  return eval { $lookup{ uc $hit->{featuretype} }($hit) } || '';
}

sub set_box {
  my ($out,$type,$key,
      $sort_field,$second_sort_field,$subtype,$num) = @_;

  my $box = ( $out->{$type}{'results'}{$key} ||= {} );

  $box->{'sort_field'} = $sort_field;
  $box->{'results'}{$subtype}{'sort_field'} = $second_sort_field;
  $box->{'results'}{$subtype}{'count'} = $num;
  $box->{'total'} += $num;
  $box->{'results'}{$subtype}{'is_clipped_flag'} = '>' if $num == 10000;
}

#add a sort_field to order the results by - species common name if it exists, domain type if it doesn't
sub summary_sort_field {
  my ($self,$domain) = @_;

  my $species_defs = $self->hub->species_defs;
  ( my $sort_field = $domain ) =~  s/ /_/g;
  return $species_defs->get_config($sort_field,'SPECIES_COMMON_NAME') ||
    $sort_field;
}

sub help_type_domain {
  my ($self,$domain) = @_;

  my $species_defs = $self->hub->species_defs;
  my $sitetype    = $species_defs->ENSEMBL_SEARCHTYPE ? lc $species_defs->ENSEMBL_SEARCHTYPE : lc($species_defs->ENSEMBL_SITETYPE);
  return ($domain =~ /${sitetype}_(faq|glossary|help|docs)/ );
}

sub general_domain {
  return (any {$_ eq $_[0]} @SiteDefs::ENSEMBL_LUCENE_OMITSPECIESFILTER);
}

sub get_results_summary {
  my ( $self, $wrapper ) = @_;

  my $new_groups = {};
  my $general_query = $self->general_query_string;
  my $specific_query = $self->specific_query_string;
  if($general_query ne $specific_query) { 
    $self->get_results_summary_part($new_groups,$wrapper,
                                    $general_query,
                                    sub { general_domain(@_) });
    $self->get_results_summary_part($new_groups,$wrapper,
                                    $specific_query,
                                    sub { not general_domain(@_) });
  } else {
    $self->get_results_summary_part($new_groups,$wrapper,$specific_query);
  }
  $self->groups($new_groups);
  $self->__status('search');
}

sub get_results_summary_part {
  my ( $self,$new_groups, $wrapper,$query,$filter ) = @_;
  my $species_defs = $self->hub->species_defs;
  my $domain_root  = $species_defs->LUCENE_DOMAINROOT || die "LUCENE_DOMAINROOT NOT SET";

  my $new_results  = $wrapper->getHeadlineNumberOfResultsByDomain( $domain_root, $query, 'species' );
 
  my ($main_total,$help_total) = (0,0);
  foreach my $new_res ( @{ $new_results->{'domain_hits'} } ) {
    my $domain = $new_res->{'domainId'};

    next if $filter and !$filter->($domain);
    next if $domain eq 'ensemblLists'; # Remove ensemblLists hits
    next if $new_res->{'NumOfResults'} <= 0;

    my $subfield_results = $new_res->{'subFieldResults'}{'FieldResult'};
    $subfield_results = [ $subfield_results ] if ref($subfield_results) eq 'HASH';
    next unless ref($subfield_results) eq 'ARRAY';

    foreach my $field_result (@$subfield_results) {
      my $count = $field_result->{'fieldNumberOfResults'};
      my $subfield = $field_result->{'fieldValue'};

      if($self->help_type_domain($domain)) {
        set_box($new_groups,'Help','Docs','Docs',$domain,$domain,$count);
        $help_total += $count;
      } else {
        my $sort_field = $self->summary_sort_field($subfield);
        set_box($new_groups,'Species',$subfield,
                $sort_field,$domain,$domain,$count);
        set_box($new_groups,'Feature type',$domain,
                $domain,$sort_field,$subfield,$count);
        $main_total += $count;
      }
    }
  }
  $new_groups->{'Species'}{'total'} += $main_total;
  $new_groups->{'Feature type'}{'total'} += $main_total;
  $new_groups->{'Help'}{'total'} += $help_total;
}

sub set_query_string {
  my $self = shift;

  my $species = $self->hub->param('species') || 'all';
  my $query_term = $self->hub->param('q');

  my $index = $self->hub->param('idx') || 'all';

  #  my $query_substring_index = "idx:$index"; # if we want to reintroduce domain filtering from the search term...

  # Lucene cannot search go terms GO:0003676 as it treats : as special.
  # solution is to escape the :

  $query_term =~ s/GO:/GO\\:/;

  my $query_substring_species = ( $species eq 'all' || !$species ? undef : "species:$species" );
  $self->general_query_string($query_term);
  $self->specific_query_string("$query_term $query_substring_species");
  return;
}

sub parse {
  my ( $self, $flag ) = @_;
  my $q = $self->hub->input;
  my $uri_path = $q->url( -absolute => 1 );

  return if $uri_path =~ /New$/;

  $self->set_query_string;

  my $wrapper = $self->Obj;

  eval {
    my $idx = $q->param('idx') || 'all';
    if ( $uri_path =~ /Results/ ) {
      $self->get_results_summary( $wrapper, $q );
    }
    else {
      $self->get_hits_details( $wrapper, $q );
    }
  };
  if ($@) {
    $self->__status('failure');
    $self->__error( $@ eq '500 read timeout' ? 'Search engine timed out' : $@ );
  }
}

sub get_hits_details {
  my ( $self, $wrapper, $q ) = @_;

  #warn "QUERY STRING ". $self->specific_query_string;
  my $domain = $q->param('idx');
  my $species_defs = $self->hub->species_defs;
  my $sitetype = $species_defs->ENSEMBL_SEARCHTYPE ? lc $species_defs->ENSEMBL_SEARCHTYPE : lc($species_defs->ENSEMBL_SITETYPE);
  $domain = $sitetype . '_' . lc($domain);
  

  my $cache = $self->hub->cache;

  # getNumberOfResults SOAP call is slow, so get it from the cache if it's there

  my $nhits_key = '::Lucene::NHITS::' . $q->param('species') . '::' . $domain . '::' . $q->param('q') . '::';

  #warn "FETCH NHITS KEY: $nhits_key";

  my $total_entries;
  $total_entries = $cache->get($nhits_key) if $cache;
  $self->nhits($total_entries);

  #warn "TOTAL ENTRIES = $total_entries";
  unless ( $total_entries > 0 ) {

    #  warn "Getting Entry count from Webservice";
    $total_entries = $wrapper->getNumberOfResults( $domain, $self->specific_query_string );

    # Cache it
    $cache->set( $nhits_key, $total_entries, 3600, 'NHITS' ) if $cache;
    $self->nhits($total_entries);
  }

  $total_entries = ( $total_entries > 10000 ? 10000 : $total_entries );

  my $pager;
  if ( $total_entries > 10 ) {
    my $key = '::Lucene::Pager::' . $q->param('species') . '::' . $domain . '::' . $q->param('q') . '::';

    # warn "MEMCACHE KEY: $key";

    $pager = $cache->get($key) if $cache;

    unless ($pager) {
      $pager = Data::Page->new();
      $pager->total_entries($total_entries);
      $pager->entries_per_page(10);
      $cache->set( $key, $pager, undef, 'PAGER' ) if $cache;
      $self->pager($pager);
    }

    $self->pager($pager);
    my $current_page = $q->param('page');
    $pager->current_page($current_page);
  }

  my $start_hit = $pager ? $pager->first - 1 : 0;
  my $fields = [
      'id',          'name', 'description',      'species', 'featuretype', 'source',
      'location',    'db',   'contigviewbottom', 'content', 'title',       'url',
      'displayname', 'keyword', 'subtype', 'evidence'
    ];
  my $domain_hits = $wrapper->getResultsAsHashArray( $domain, $self->specific_query_string, $fields, $start_hit, 10 );

  map { $_->{feature_url} = $self->feature2url($_) } @$domain_hits;
  $self->hits($domain_hits);

  #my @ids = map {$_->{id}} @$domain_hits;
  # my $ids_to_urls = $wrapper->getEntriesFieldUrls($domain ,\@ids,['id']);
  # warn dump $ids_to_urls;
  # $self->url_lookup($ids_to_urls);
}


1;
