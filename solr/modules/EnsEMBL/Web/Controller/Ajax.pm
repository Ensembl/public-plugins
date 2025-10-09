=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Controller::Ajax;

use strict;

use URI::Escape qw(uri_escape);
use JSON qw(from_json to_json);
use LWP::UserAgent;
use List::MoreUtils qw(natatime);
use Bio::EnsEMBL::DBSQL::GeneAdaptor;
use EnsEMBL::Web::Controller::Psychic;

use EnsEMBL::Web::Tools::FailOver::Solr;

sub common {
  my ($self,$hub,$scientific) = @_;

  return $hub->species_defs->get_config($scientific,'SPECIES_DISPLAY_NAME');
}

sub search_connect {
  my ($self,$hub,$endpoint,$timeout,$tryhard) = @_; 

  my ($result,$error) = ("","");
  undef $@; 
  my $url;
  eval {
    my $ua = LWP::UserAgent->new;
    my $proxy = $hub->web_proxy;
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
    foreach my $k (qw(q fq rows facet facet.field facet.limit facet.mincount start sort hl hl.fl facet.prefix indent hl.fragsize spellcheck spellcheck.count spellcheck.onlyMorePopular spellcheck.q)) {
      my @v = $hub->param($k);
      push @params,$k,$_ for @v;
    }     
    my @param_str;
    my $ps = natatime(2,@params);
    while(my @kv = $ps->()) {
      push @param_str,$kv[0]."=".uri_escape($kv[1]);
    }     
    $url = $endpoint;
    if($hub->param('spellcheck.q')) {
      $url =~ s#\/[^/]*$#/spell#g; ##
    } elsif($hub->param('directlink')) {
      $url =~ s#\/[^/]*$#/directlink#g; ##
    } elsif($hub->param('spellcheck')) {
      $url =~ s#\/[^/]*$#/suggest#g; ##
    }     
    $url = "$url?".join("&",@param_str);
    #warn "URL = $url\n";
    my $response = $ua->get($url);

    if($response->is_success) {
      $result = from_json($response->content);
    } else {
      $error = "Server returned status ".$response->code." ".$response->message;
    }     
  };
  if($@) {
    $error = "Error contacting server: $@";
  }
  warn "SOLR: $error on $url\n" if $error;
  return { result => $result, error => $error };
}


sub ajax_search {
  my ($self,$hub) = @_;

  my $failover = EnsEMBL::Web::Tools::FailOver::Solr->new($hub);

  my $out = $failover->go({ self => $self, hub => $hub });
  unless(defined $out) {
    $out = { result => {}, error => "Cannot connect to any servers" };
  }
  print $self->jsonify($out);
}

sub ajax_species {
  my ($self,$hub) = @_;

  my $out = [];
  my $names = $hub->param('name');
  my $sd = $hub->species_defs;
  foreach my $name_in (split(/,/,$names)) {
    my $name = $name_in;
    $name =~ s/ /_/g;
    $name = lc($name);
    $name = "fly" if $name eq "fruitfly"; # XXX why is this not an alias?
    $name = $SiteDefs::ENSEMBL_SPECIES_ALIASES->{$name} || $name;    
    my $common = $sd->get_config($name,'SPECIES_DISPLAY_NAME');
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
      common => $sd->get_config($name,'SPECIES_DISPLAY_NAME'),
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
sub ajax_extra {
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

sub ajax_config {
  my ($self,$hub) = @_;

  my @favs = map { $self->common($hub,$_) } @{$hub->get_favourite_species};
  my $species_info = $hub->get_species_info;

  my $spnames = {};
  my $revspnames = {};
  foreach my $sp (keys %$species_info) {
    my @names;
    my $name = $species_info->{$sp}{'common'};
    push @names,$name,lc($name);
    my $latin = $species_info->{$sp}{'key'};
    $revspnames->{$latin} = $name;
    $revspnames->{lc $latin} = $name;
    foreach my $name (@names) {
      $spnames->{$name} = $latin;
    }
  }

  print to_json({
    static => $self->solr_config(),
    spnames => $spnames,
    revspnames => $revspnames,
    user => {
      favs => {
        species => \@favs,
      },
    },
  });

}

# separating the solar configuration, can be overwritten in plugins (no need to be in sitedefs)
sub solr_config {
  my $self = @_;

  return $SiteDefs::ENSEMBL_SOLR_CONFIG;
}

sub ajax_echo { # XXX For table downloads, shouldn't be in search plugin
  my ($self,$hub) = @_;

  print $hub->param('data'); 
}

sub _tid_to_trans {
  my ($self,$hub,$species,$tid) = @_;

  my $t_a = $hub->get_adaptor('get_TranscriptAdaptor','core',$species);
  return undef unless $t_a;
  return $t_a->fetch_by_stable_id($tid);
}

sub _pid_to_trans {
  my ($self,$hub,$species,$pid) = @_;

  my $p_a = $hub->get_adaptor('get_TranslationAdaptor','core',$species);
  return undef unless $p_a;
  my $p = $p_a->fetch_by_stable_id($pid);
  return undef unless $p;
  my $t = $p->transcript();
  return undef unless $t;
  return $t;
}

sub _refseq_to_trans {
  my ($self,$hub,$species,$rid) = @_;

  my $t_a = $hub->get_adaptor('get_TranscriptAdaptor','core',$species);
  return undef unless $t_a;
  my $trans = $t_a->fetch_all_by_external_name($rid); # XXX do it properly
  return undef unless @$trans;
  return $trans->[0];
}

sub _hgvs_to_vid {
  my ($self,$hub,$species,$hgvs,$ref) = @_;

  my @out;
  eval {
    my $vf_a = $hub->get_adaptor('get_VariationFeatureAdaptor','variation',$species);
    my $vf = $vf_a->fetch_by_hgvs_notation($hgvs);
    return undef unless $vf;
    my $slice = $vf->slice->sub_Slice($vf->start,$vf->end);
    foreach my $vf (@{$vf_a->fetch_all_by_Slice($slice)}) {
      my $found = 0;
      my @ids;
      foreach my $type (qw(g c p)) {
        foreach my $notation (values %{$vf->get_all_hgvs_notations($ref,$type)}) {
          push @ids,$notation;
          if($notation eq $hgvs) { $found = 1; }
        }
      }
      if($found) {
        push @out,{
          vf => $vf,
          hgvs => \@ids,
        };
      }
    }
  };
  return \@out;
}

sub ajax_hgvs { # XXX extend beyond HGVS to other semi-psychic things
  my ($self,$hub) = @_;

  my $id = $hub->param('id');

  my (@links,$trans,$prot,$vs);
  $trans = $self->_tid_to_trans($hub,'Homo_sapiens',$1) if $id =~ /^(ENST\d{11})\W/;
  $trans = $self->_pid_to_trans($hub,'Homo_sapiens',$1) if $id =~ /^(ENSP\d{11})\W/;
  $trans = $self->_refseq_to_trans($hub,'Homo_sapiens',$1) if $id =~ /^([A-Z]{2}\_[\d\.]{5,})\W/;
  my $new_id = $id;
  if($trans) {
    $new_id =~ s/^.*?\://;
    my $v = '';
    $v = ".".$trans->translation->version if $trans->translation;
    $new_id = $trans->stable_id.$v.":$new_id";
  }
  if($id) {
    $vs = $self->_hgvs_to_vid($hub,'Homo_sapiens',$new_id,$trans);
  }
  foreach my $v (@$vs) {
    my $vid = $v->{'vf'}->variation()->stable_id();
    my $tail = ", which matches.";
    if(@{$v->{'hgvs'}}) {
      $tail =
        ", which includes HGVS identifiers ".join(', ',@{$v->{'hgvs'}});
    }
    push @links,{
      text => "View variation '$vid'",
      tail => $tail,
      url => "/Homo_sapiens/Variation/Explore?v=$vid",
    };
  }
  if($trans) {
    my $enstid = $trans->stable_id();
    push @links,{
      text => "View whole transcript $enstid",
      url => "/Homo_sapiens/Transcript/Summary?db=core;t=$enstid",
    };
    my $prot = $trans->translation();
    if($prot) {
      my $enspid = $prot->stable_id();
      push @links,{
        text => "View whole protein $enspid",
        url => "/Homo_sapiens/Transcript/ProteinSummary?db=core;p=$enspid",
      };
    }
  }
  print to_json({ id => $id, links => \@links });
}

# Redirect or not, depending on the psychic response
sub ajax_psychic {
  my ($self, $hub) = @_;

  # Create temporary mock object to call psychic
  my $psychic_obj = bless {}, "EnsEMBL::Web::Controller::Psychic";
  $psychic_obj->{"hub"} = $hub;
  $psychic_obj->{"species_defs"} = $hub->species_defs;
  my $location = $psychic_obj->psychic_no_redir();
  warn "Ajax Psychic redir URL: $location";

  if ($location =~ m!^/[^/]+/Psychic! or $location =~ m!/Search/Results?!) {
    print to_json({ redirect => 0 });
  } else {
    print to_json({ redirect => 1, url => $location });
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

