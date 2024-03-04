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
  my $proxy = $self->{'hub'}->web_proxy;
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

