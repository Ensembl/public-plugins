package EnsEMBL::Web::Controller::Ajax;

use strict;

use SiteDefs qw(:APACHE);

use URI::Escape qw(uri_escape);
use JSON qw(from_json to_json);
use LWP::UserAgent;
use List::MoreUtils qw(natatime);
use Bio::EnsEMBL::DBSQL::GeneAdaptor;
use EnsEMBL::Web::Hub;

use EnsEMBL::Web::Tools::FailOver::Solr;

sub common {
  my ($self,$hub,$scientific) = @_;

  return $hub->species_defs->get_config($scientific,'SPECIES_COMMON_NAME');
}

sub search_connect {
  my ($self,$hub,$endpoint,$timeout,$tryhard) = @_; 

  my ($result,$error) = ("","");
  undef $@; 
  eval {
    my $ua = LWP::UserAgent->new;
    my $proxy = $hub->species_defs->ENSEMBL_WWW_PROXY;
    $proxy = undef if($SiteDefs::SOLR_NO_PROXY);
    $ua->proxy('http',$proxy) if $proxy;
    $ua->timeout($timeout) unless $tryhard;
    my $page = ($hub->param('page') || 1);
    my $start = $hub->param('start') || 0; 
    if($hub->param('page')) {
      $start = ($page-1)*($hub->param('rows'));
    }     
    my @params = (
      wt => 'json',
      start => $start
    );    
    foreach my $k (qw(q fq rows facet facet.field facet.mincount start sort hl hl.fl facet.prefix indent hl.fragsize spellcheck spellcheck.count spellcheck.onlyMorePopular spellcheck.q)) {
      my @v = $hub->param($k);
      push @params,$k,$_ for @v;
    }     
    my @param_str;
    my $ps = natatime(2,@params);
    while(my @kv = $ps->()) {
      push @param_str,$kv[0]."=".uri_escape($kv[1]);
    }     
    my $url = $endpoint;
    if($hub->param('spellcheck.q')) {
      $url =~ s#\/[^/]*$#/spell#g; ##
    } elsif($hub->param('spellcheck')) {
      $url =~ s#\/[^/]*$#/suggest#g; ##
    }     
    $url = "$url?".join("&",@param_str);
    my $response = $ua->get($url);

    if($response->is_success) {
      $result = from_json($response->decoded_content);
    } else {
      $error = "Server returned status ".$response->code." ".$response->message;
    }     
  };
  if($@) {
    $error = "Error contacting server: $@";
  }
  warn "SOLR: $error\n" if $error;
  return { result => $result, error => $error };
}


sub search {
  my ($self,$hub) = @_;

  my $failover = EnsEMBL::Web::Tools::FailOver::Solr->new($hub);

  my $out = $failover->go({ self => $self, hub => $hub });
  unless(defined $out) {
    $out = { result => {}, error => "Cannot connect to any servers" };
  }
  print $self->jsonify($out);
}

sub species {
  my ($self,$hub) = @_;

  my $out = [];
  my $names = $hub->param('name');
  my $sd = $hub->species_defs;
  foreach my $name_in (split(/,/,$names)) {
    my $name = $name_in;
    $name =~ s/ /_/g;
    $name = lc($name);
    $name = "fly" if $name eq "fruitfly"; # XXX why is this not an alias?
    $name = $ENSEMBL_SPECIES_ALIASES->{$name} || $name;    
    my $common = $sd->get_config($name,'SPECIES_COMMON_NAME');
    next unless $common;
    push @$out,{
      common => $common,
      url => $name,
      orig => $name_in
    };
  }
  my $fav_in = $hub->get_favourite_species;
  my @favs;
  foreach my $name (@$fav_in) {
    push @favs, {
      common => $sd->get_config($name,'SPECIES_COMMON_NAME'),
      url => $name
    };
  }
  print $self->jsonify({ result => $out, favs => \@favs });
}

# XXX move extra impls into separate file

sub extra_biotype {
  my ($self,$hub,$obj,$req) = @_;

  return undef unless $obj;
  return $obj->biotype;
}

# XXX use logic in drawing code
sub extra_bt_colour {
  my ($self,$hub,$obj,$q) = @_;

  return undef unless $obj;
  my $key;
  $key = 'merged' if $obj->analysis->logic_name =~ /ensembl_havana/;
  $key = $obj->biotype unless $key;
  my $largekey = $obj->analysis->logic_name.'_'.$key;
  my $sets = $hub->species_defs->get_config('MULTI','COLOURSETS');
  my $name = $sets->{'gene'}{$largekey}{'default'} ||
             $sets->{'gene'}{$key}{'default'};
  return $hub->colourmap->hex_by_name($name);
}

# XXX merge species and extra
sub extra {
  my ($self,$hub) = @_;

  my $queries = from_json($hub->param('queries'));
  my %results = ();
  foreach my $q (@{$queries->{'queries'}}) {
    foreach my $req (@{$q->{'req'}}) {
      $req =~ s/[^a-z_]//g; # strict because user-supplied
      my $method = "extra_$req";
      my $obj = undef;
      #
      my $ad = undef;
      if($q->{'ft'} eq 'Gene') {
        $ad = $hub->get_adaptor("get_GeneAdaptor",$q->{'db'},$q->{'species'});
      }
      if($ad) {
        $obj = $ad->fetch_by_stable_id($q->{'id'});
      }
      #
      my $result = undef;
      $result = $self->$method($hub,$obj,$q) if $self->can($method);
      $results{$q->{'myref'}||'result'} ||= [];
      push @{$results{$q->{'myref'}||'result'}},$result;
    }
  }
  print to_json(\%results);
}

sub config {
  my ($self,$hub) = @_;

  my @favs = map { $self->common($hub,$_) } @{$hub->get_favourite_species};
  my $species_info = $hub->get_species_info;

  my $spnames = {};
  $spnames->{$species_info->{$_}{'common'}} = $species_info->{$_}{'key'} for keys %$species_info;
  print to_json({
    static => $SiteDefs::ENSEMBL_SOLR_CONFIG,
    spnames => $spnames,
    user => {
      favs => {
        species => \@favs,
      },
    },
  });

}

sub echo { # XXX For table downloads, shouldn't be in search plugin
  my ($self,$hub) = @_;

  print $hub->param('data'); 
}

sub psychic { # Invoke psychic via AJAX, to see if we need to redirect.
  my ($self,$hub) = @_;

  # XXX this is a horrible way to do it: we should somehow create a
  #   fake call to psychic or else make psychic more flexible to allow
  #   internal calls to its own algorithm.
  my $ua = LWP::UserAgent->new;
  my $proxy = $hub->species_defs->ENSEMBL_WWW_PROXY;
  $proxy = undef if($SiteDefs::SOLR_NO_PROXY);
  $ua->proxy('http',$proxy) if $proxy;
  $ua->requests_redirectable([]);
  my $psychic = $hub->species_defs->ENSEMBL_BASE_URL.
             "/Multi/psychic?q=".uri_escape($hub->param('q'));
  my $response = $ua->get($psychic);
  my $location;
  if($response->is_redirect) {
    $location = $response->header("Location");
    if($location and
         ($location =~ m!^/[^/]+/psychic! or
          $location =~ m!/Search/Results?!  )) {
      $location = undef;
    }
  }
  if($location) {
    print to_json({ redirect => 1, url => $location });
  } else {
    print to_json({ redirect => 0 });
  }     
}

# XXX configurable disable
sub report_error {
  my ($self,$hub) = @_;

  warn "----- ".uc($hub->param('type'))." from user's browser -----\n";
  warn "Session: ".$hub->session->session_id."\n";
  warn "Time: ".localtime(time)."\n";
  warn "Message: ".$hub->param("msg")."\n";
  warn "URL: ".$hub->param("url")."\n";
  warn "Line: ".$hub->param("line")."\n";
  warn "Features: ".$hub->param("support")."\n";
  warn "Browser: ".$hub->apache_handle->headers_in->{'User-Agent'}."\n";
  warn "-------------------------\n";
}

1;

