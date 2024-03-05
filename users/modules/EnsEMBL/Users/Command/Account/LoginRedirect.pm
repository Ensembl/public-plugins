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

package EnsEMBL::Users::Command::Account::LoginRedirect;

### Command used to reach from same url as the actual Login page, but only in case a user is already logged in
### @author hr5

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $site    = $hub->species_defs->ENSEMBL_SITE_URL;
  my $then    = $object->get_then_param;

  return $self->ajax_redirect($then =~ /^(\/|$site)/ ? $then : $site); # only redirect to an internal url or a relative url
}

1;
