package EnsEMBL::Web::Tools::FailOver::Solr;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Tools::FailOver);

use LWP::UserAgent;

sub new {
  my ($proto,$hub) = @_;

  my $self = $proto->SUPER::new("solr");
  my $config = $hub->species_defs->ENSEMBL_SOLR_ENDPOINT;
  $config = [ $config ] unless ref $config eq 'ARRAY';
  $self->{'endpoints'} = {};
  $self->{'endpoint_order'} = [];
  $self->{'hub'} = $hub;
  foreach my $ep (@$config) {
    my ($url,$timeout,$check_url) = ($ep,30,$ep);
    ($url,$timeout,$check_url) = @$ep if ref($ep) eq 'ARRAY';
    $check_url = $url unless $check_url;
    $self->{'endpoints'}{$url} = {
      timeout => $timeout,
      check_url => $check_url,
    };
    push @{$self->{'endpoint_order'}},$url;
  }
  return $self;
}

my $min_bytes = 50; # Many failures return, but with no content.
sub liveness_check {
  my ($self,$endpoint) = @_; 

  my $check_url = $self->{'endpoints'}{$endpoint}{'check_url'};
  return 0 unless defined $check_url;
  my $ua = LWP::UserAgent->new;
  my $proxy = $self->{'hub'}->species_defs->ENSEMBL_WWW_PROXY;
  $ua->proxy('http',$proxy) if $proxy;
  $ua->timeout(5);
  my $response = $ua->get($check_url);
  if($response->is_success) {
    return length($response->decoded_content) >= $min_bytes;
  } else {
    return 0;
  }
}

sub fail_for {
  return $_[0]->{'hub'}->species_defs->ENSEMBL_SOLR_FAILFOR || 600;
}
sub failure_dir { return $_[0]->{'hub'}->species_defs->ENSEMBL_FAILUREDIR; }
sub endpoints { return $_[0]->{'endpoint_order'}; }

sub attempt {
  my ($self,$endpoint,$payload,$tryhard) = @_;

  my $timeout = $self->{'endpoints'}{$endpoint}{'timeout'};
  return $payload->{'self'}->search_connect($payload->{'hub'},
                                            $endpoint,$timeout,$tryhard);
}

sub successful {
  my ($self,$out) = @_;

  return (defined $out and !$out->{'error'});
}

1;

