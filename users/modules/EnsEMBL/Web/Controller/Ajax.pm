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

use EnsEMBL::Web::Document::Element::AccountLinks;
use EnsEMBL::Users::Component::Account::Login;

sub ajax_accounts_dropdown {
  my ($self, $hub) = @_;
  
  print EnsEMBL::Web::Document::Element::AccountLinks->new({'hub' => $hub})->content_ajax;

  if (!$hub->user) {
# TODO
#    print EnsEMBL::Users::Component::Account::Login->new($hub)->login_form(1)->render;
  }
}

1;
