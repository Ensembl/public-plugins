=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Command::Account::Logout;

### Command to clear user cookies
### @author hr5

use strict;

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $hub     = $self->hub;

  # clears cookies & saved user object
  $hub->user->deauthorise;

  # redirect to the right page depending upon the referer
  my $referer = $hub->referer;

  return $self->ajax_redirect($referer->{'external'} || $referer->{'ENSEMBL_TYPE'} eq 'Account' ? '/' : $referer->{'absolute_url'}, {}, '', 'page');
}

1;