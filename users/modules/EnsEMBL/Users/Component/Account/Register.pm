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

package EnsEMBL::Users::Component::Account::Register;

### Component for new user Registeration page
### @author hr5

use strict;

use parent qw(EnsEMBL::Users::Component::Account);

sub caption {
  return sprintf 'Register with %s', shift->site_name;
}

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $form    = $self->new_form({'action' => {qw(action User function Add)}, 'id' => 'registration'});

  $form->add_hidden({'name' => 'modal_tab', 'value' => 'modal_user_data', 'data-role' => 'none'});

  $form->add_field({qw(type honeypot name title   label Title)});      # honeypot fields for catching bots
  $form->add_field({qw(type honeypot name surname label Surname)});

  $self->add_user_details_fields($form, {
    'email'       => $hub->param('email') || '',
    'name'        => $hub->param('name')  || '',
    'email_notes' => sprintf("You'll use this to log in to %s.", $self->site_name)
  });

  my $html = '<input type="hidden" class="subpanel_type" value="Register" />';

  $html .= $self->js_section({'subsections' => [ $form->render ]});

  $html .= '<div id="message_placeholder"></div>';

  return $html;
}

1;
