=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::Account;

### Plugin file for Account object in the users plugin

use strict;

sub login_has_trusted_provider {
  ## In case of an openid login, tells whether the provider is trusted or not.
  ## @return 1 if trusted openid provider, 0 if not trusted or if login is not of type openid
  my ($self, $login) = @_;

  return $login->type eq 'openid' ? {@{$self->hub->species_defs->OPENID_PROVIDERS}}->{$login->provider}->{'trusted'} : 0;
}

1;