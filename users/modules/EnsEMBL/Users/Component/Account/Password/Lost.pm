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

package EnsEMBL::Users::Component::Account::Password::Lost;

### Create a form for the user to be able to request for lost password
### @author hr5

use strict;

use parent qw(EnsEMBL::Users::Component::Account);

sub caption {
  return 'Lost Password';
}

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $form      = $self->new_form({'action' => {qw(action Password function Retrieve)}});
  my $ex_email  = $hub->param('email');

  $form->add_notes(sprintf q(<p>If you have lost your password, please enter your email address used while registering to %s and we will send you an email to retrieve your password.</p>), $self->site_name);
  $form->add_field({'type'  => 'Email',  'name'  => 'email',   'label' => 'Email', 'required'  => 'yes', $ex_email ? ('value' => $ex_email) : ()});
  $form->add_button({'type' => 'Submit', 'name'  => 'submit',  'value' => 'Send'});

  $_->set_attribute('data-role', 'none') for @{$form->get_elements_by_tag_name('input')};

  return $self->js_section({'subsections' => [ $form->render ]});
}

1;
