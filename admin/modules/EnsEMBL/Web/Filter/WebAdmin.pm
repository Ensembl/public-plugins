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

package EnsEMBL::Web::Filter::WebAdmin;

use strict;

use parent qw(EnsEMBL::Web::Filter);

sub init {
  my $self = shift;
  my $sd   = $self->hub->species_defs;

  $self->messages = {
    restricted => sprintf('These pages are restricted to members of the %s webadmin group. If you require access, please contact the %1$s Web Team.', $sd->ENSEMBL_SITETYPE),
  };
}

sub catch {
  my $self = shift;
  my $hub  = $self->hub;
  my $user = $hub->user;
  my $sd   = $hub->species_defs;

  $self->redirect   = sprintf('%s%s%s', '/Account/Login?then=', $sd->ENSEMBL_BASE_URL, $hub->url);
  $self->error_code = 'restricted' unless $user && $user->is_member_of($sd->ENSEMBL_WEBADMIN_ID);
}

1;