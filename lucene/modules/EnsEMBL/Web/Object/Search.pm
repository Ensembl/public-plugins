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

sub default_action { return 'New'; }

sub short_caption  { 
  my ($self, $search_type) = @_;
  my $sitetype = $self->species_defs->ENSEMBL_SITETYPE || 'Ensembl'; 
  return $search_type eq 'global' ? 'New Search' : "Search $sitetype"; 
}

sub caption {
  my $self = shift; 
  my $sitetype = $self->species_defs->ENSEMBL_SITETYPE || 'Ensembl'; 
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

sub query_string { 
  my ($self, $qs) = @_; 
  $self->{'data'}{'query_string'} = $qs if $qs; 
  return $self->{'data'}{'query_string'}; 
}

sub results_summary { 
  my ($self, $rs) = @_; 
  $self->{'data'}{'results_summary'} = $rs if $rs; 
  return $self->{'data'}{'results_summary'}; 
}


sub feature2url {
    my ( $self, $hit ) = @_;
    my $species = $self->Obj->{species};
    my $id      = $self->Obj->{id};

    my %lookup = (
        'MARKER' => sub { return "$species/Marker/Details?m=$id;contigviewbottom=marker_core_marker" },
        'DOMAIN' => sub { return "$species/Location/Genome/?ftype=$self->{featuretype};id=$id" },
        'FAMILY' => sub { return "$species/Gene/Family/Genes?family=$id" },
        'GENOMICALIGNMENT' => sub {
            return "$self->{species_path}/featureview?type=$self->{Source};id=$id"
              . ( $self->{db} ? '' : ";db=$self->{db}" );
        },
        'OLIGOPROBE' => sub { return "$self->{species_path}/featureview?type=OligoProbe;id=$id" },
        'QTL'        => sub { return "$self->{species_path}/contigview/l&%s" },
        'GENOMIC'    => sub {
            return
                "$self->{species_path}/"
              . ( $self->{length} > 0.5e6 ? 'cytoview' : 'contigview' )
              . "?mapfrag=$self->{Name}";
        },
        'SNP'       => sub { return "$species/Variation/Summary?v=$id;source=$self->{source}" },
        'VARIATION' => sub { return "$species/Variation/Summary?v=$id;source=$self->{source}" },
        'GENE' =>
          sub { return "$species/Gene/Summary?g=$id" . ( $self->{db} ? ";db=$self->{db}" : '' ) },
        'TRANSCRIPT' =>
          sub { return "$species/Transcript/Summary?t=$id" . ( $self->{db} ? ";db=$self->{db}" : '' ) },
        'IDHISTORY_GENE'        => sub { return "$species/Gene/Idhistory?g=$id" },
        'IDHISTORY_TRANSCRIPT'  => sub { return "$species/Transcript/Idhistory?t=$id" },
        'IDHISTORY_TRANSLATION' => sub { return "$species/Transcript/Idhistory?protein=$id" },
        'QTL'                   => sub { return "$species/Location/View?r=$self->{location}" },
        'UNMAPPEDFEATURE'       => sub { return "$self->{species_path}/featureview?type=Gene;id=$id" },
        'PROBEFEATURE'          => sub {
            return "$species/Location/Genome?ftype=ProbeFeature;fdb=funcgen;id=$id;ptype="
              . ( $self->{description} =~ /set/ ? "pset;" : "probe;" );
        },
        'PROTEINALIGNFEATURE' => sub {
            return
                "$species/Location/Genome?ftype=$self->{featuretype};id=$id"
              . ( $self->{db} ? ";db=$self->{db}" : '' )
              . ( $self->{contigviewbottom} ? ";contigviewbottom=$self->{contigviewbottom}" : '' );
        },
        'DNAALIGNFEATURE' => sub {
            return
                "$species/Location/Genome?ftype=DnaAlignFeature;id=$id"
              . ( $self->{db} ? ";db=$self->{db}" : '' )
              . ( $self->{contigviewbottom} ? ";contigviewbottom=$self->{contigviewbottom}" : '' );
        },
        'PHENOTYPE' => sub {
            return
              "$species/Location/Genome?ftype=Phenotype;id=$id;phenotype_name=$self->{description}";
        },
        'SEQUENCE' => sub {
            return $id =~ /^LRG/
              ? "$species/LRG/Summary?lrg=$id"
              : "$species/Location/View?r=$self->{location}";
        },
        'STRUCTURALVARIATION' => sub { return "$species/StructuralVariation/Summary?sv=$id" },
        'REGULATORYFEATURE'   => sub {
            return $id =~ /ENSR|ENSMUSR/
              ? "$species/Regulation/Cell_line?rf=$id"
              : "$species/Location/Genome?ftype=RegulatoryFactor;id=$id;fset=$self->{subtype}";
        },
        'FAQ'      => sub { return "common/Help/Faq#faq$id" },
        'GLOSSARY' => sub { return "common/Help/Glossary?id=$id" },
        'VIEW'     => sub { return "common/Help/View?id=$id" },
    );
    $hit->{species} =~ s/ /_/g;
    return eval { $lookup{ uc $hit->{featuretype} }($hit) } || '';
}


sub get_results_summary {
    my ( $self, $wrapper ) = @_;
    my $groups;
    my $query = $self->query_string;

    my $species_defs = $self->hub->species_defs;
    my $domain_root  = $species_defs->LUCENE_DOMAINROOT || die "LUCENE_DOMAINROOT NOT SET";
    my $new_results  = $wrapper->getHeadlineNumberOfResultsByDomain( $domain_root, $query, 'species' );

    my $is_clipped;
    my $new_groups;
    foreach my $new_res ( @{ $new_results->{domain_hits} } ) {

        #         warn dump $new_res;

        # Remove ensemblLists hits
        if ( $new_res->{domainId} eq 'ensemblLists' ) {
            $new_results->{total} -= $new_res->{NumOfResults};
            next;
        }
        next if $new_res->{NumOfResults} <= 0;

        my $subfield_results = $new_res->{subFieldResults}->{FieldResult};

       #    warn dump $subfield_results;
        if ( ref $subfield_results eq 'ARRAY' ) {
            $DB::single = 1;
            foreach my $field_result (@$subfield_results) {

                # Handle Help and Docs totals like this until it gets a dedicated subdmain in the lucene hierarchy
                if ( $new_res->{domainId} =~ /ensembl_faq|ensembl_glossary|ensembl_help|ensembl_docs/ ) {

                    # warn "ARRAY  $new_res";
                    $new_groups->{Help}->{results}->{"Docs"}->{results}->{ $new_res->{domainId} }->{count} =
                      $subfield_results->{fieldNumberOfResults};
                    $new_groups->{Help}->{results}->{"Docs"}->{total} += $subfield_results->{fieldNumberOfResults};
                    next;

                }
                $new_groups->{Species}->{results}->{ $field_result->{fieldValue} }->{results}->{ $new_res->{domainId} }
                  ->{count} = $field_result->{fieldNumberOfResults};

                $new_groups->{Species}->{results}->{ $field_result->{fieldValue} }->{total} +=
                  $field_result->{fieldNumberOfResults};

                #        $new_groups->{Species}->{results}->{ $field_result->{fieldValue} }->{is_clipped_flag} = '>'

                $new_groups->{Species}->{results}->{ $field_result->{fieldValue} }->{results}->{ $new_res->{domainId} }
                  ->{is_clipped_flag} = '>'
                  if $field_result->{fieldNumberOfResults} == 10000;

                $new_groups->{'Feature type'}->{results}->{ $new_res->{domainId} }->{results}
                  ->{ $field_result->{fieldValue} }->{count} = $field_result->{fieldNumberOfResults};

                $new_groups->{'Feature type'}->{results}->{ $new_res->{domainId} }->{total} +=
                  $field_result->{fieldNumberOfResults};

                $new_groups->{'Feature type'}->{results}->{ $new_res->{domainId} }->{results}
                  ->{ $field_result->{fieldValue} }->{is_clipped_flag} = '>'
                  if $field_result->{fieldNumberOfResults} == 10000;

            }
        }
        elsif ( ref $subfield_results eq 'HASH' ) {
            $DB::single = 1;

            # Handle Help and Docs totals like this until it gets a dedicated subdmain in the lucene hierarchy
            if ( $new_res->{domainId} =~ /(faq|ensembl_glossary|ensembl_help|ensembl_docs)/ ) {

                # warn "HASH ". dump  $new_res;
                $new_groups->{Help}->{results}->{"Docs"}->{results}->{ $new_res->{domainId} }->{count} =
                  $subfield_results->{fieldNumberOfResults};
                $new_groups->{Help}->{results}->{"Docs"}->{total} += $subfield_results->{fieldNumberOfResults};

                next;
            }

            #    warn dump $subfield_results;
            $new_groups->{'Feature type'}->{results}->{ $new_res->{domainId} }->{total} +=
              $subfield_results->{fieldNumberOfResults};
            $new_groups->{Species}->{results}->{ $subfield_results->{fieldValue} }->{total} +=
              $subfield_results->{fieldNumberOfResults};

            $new_groups->{Species}->{results}->{ $subfield_results->{fieldValue} }->{results}->{ $new_res->{domainId} }
              ->{count} = $subfield_results->{fieldNumberOfResults};

            $new_groups->{Species}->{results}->{ $subfield_results->{fieldValue} }->{results}->{ $new_res->{domainId} }
              ->{is_clipped_flag} = '>'
              if $subfield_results->{fieldNumberOfResults} == 10000;

            $new_groups->{'Feature type'}->{results}->{ $new_res->{domainId} }->{results}
              ->{ $subfield_results->{fieldValue} }->{count} = $subfield_results->{fieldNumberOfResults};

            $new_groups->{'Feature type'}->{results}->{ $new_res->{domainId} }->{results}
              ->{ $subfield_results->{fieldValue} }->{is_clipped_flag} = '>'
              if $subfield_results->{fieldNumberOfResults} == 10000;
        }
    }

    $new_groups->{Species}->{total} = $new_results->{total} - $new_groups->{Help}->{results}->{Docs}->{total};
    $new_groups->{'Feature type'}->{total} = $new_results->{total} - $new_groups->{Help}->{results}->{Docs}->{total};

    # until help and docs gets a subdomain by itself....
    $new_groups->{Help}->{total} = $new_groups->{Help}->{results}->{Docs}->{total};

    #   $new_groups->{'Help and Docs'} = $new

    #print Dumper @test_list;
#    warn dump $new_groups;

    $self->groups($new_groups);
    $self->__status('search');
    return;

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

    # warn "QUERY TERM -> $query_term";

    my $query_substring_species = ( $species eq 'all' || !$species ? undef : "species:$species" );
    my $query_string = "$query_term $query_substring_species";
    $self->query_string($query_string);
    return;
}

sub parse {
    my ( $self, $flag ) = @_;
    my $q = $self->hub->input;
    my $uri_path = $q->url( -absolute => 1 );

#     if ( $uri_path =~ /Multi/ ) {
#         return
#     qq{<div class="info-box ">Searching  all species at once is currently not possible whilst we're developing the lucene backend, this functionality will appear soon.                              }
#
#     }

    return if $uri_path =~ /New$/;

    $self->set_query_string;

    my $wrapper = $self->Obj;

    eval {
        my $idx = $q->param('idx') || 'all';

        #    if ( $idx eq 'all' || $q->param('species') eq 'all') {

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

    #warn "QUERY STRING ". $self->query_string;
    my $domain = $q->param('idx');

    $domain = 'ensembl_' . lc($domain);

    my $cache = $self->hub->cache;

    # getNumberOfResults SOAP call is slow, so get it from the cache if
    # it's there

    my $nhits_key = '::Lucene::NHITS::' . $q->param('species') . '::' . $domain . '::' . $q->param('q') . '::';

    #warn "FETCH NHITS KEY: $nhits_key";

    my $total_entries;
    $total_entries = $cache->get($nhits_key) if $cache;
    $self->nhits($total_entries);

    #warn "TOTAL ENTRIES = $total_entries";
    unless ( $total_entries > 0 ) {

        #  warn "Getting Entry count from Webservice";
        $total_entries = $wrapper->getNumberOfResults( $domain, $self->query_string );

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
        'displayname', 'keyword'
    ];
    my $domain_hits = $wrapper->getResultsAsHashArray( $domain, $self->query_string, $fields, $start_hit, 10 );

    map { $_->{feature_url} = $self->feature2url($_) } @$domain_hits;

    $self->hits($domain_hits);

    #my @ids = map {$_->{id}} @$domain_hits;
    # my $ids_to_urls = $wrapper->getEntriesFieldUrls($domain ,\@ids,['id']);
    # warn dump $ids_to_urls;
    # $self->url_lookup($ids_to_urls);
}


1;
