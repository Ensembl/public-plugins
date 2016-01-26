=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::OpenID::Command::Account;

use strict;
use warnings;

use Net::OpenID::Consumer;
use LWP::UserAgent;

use base qw(EnsEMBL::Users::Command::Account);

use constant {
  OPENID_EXTENSION_URL_AX   => 'http://openid.net/srv/ax/1.0',
  OPENID_EXTENSION_URL_SREG => 'http://openid.net/extensions/sreg/1.1',
};

sub get_openid_consumer {
  ## Gets the openid consumer object used for openid login process
  ## @return Net::OpenID::Consumer
  my $self    = shift;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $ua      = LWP::UserAgent->new;

  $ua->proxy([qw(http https)], $_) for $sd->ENSEMBL_WWW_PROXY || ();

  return Net::OpenID::Consumer->new(
    'ua'              => $ua,
    'required_root'   => $self->object->get_root_url,
    'args'            => $hub->input,
    'consumer_secret' => $sd->OPENID_CONSUMER_SECRET,
  );
}

1;