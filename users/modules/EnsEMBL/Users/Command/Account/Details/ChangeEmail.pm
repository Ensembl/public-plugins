=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Command::Account::Details::ChangeEmail;

### Command to change the user email - user lands on this page after clicking on the link sent to him via email for the purpose of verifying his new email address
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_EMAIL_CHANGED MESSAGE_URL_EXPIRED);

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;

  my $login     = $object->fetch_login_from_url_code;
  my $email     = $self->validate_fields({'email' => $hub->param('email') || ''})->{'email'} || '';

  if ($login && $email) {

    # logout the logged-in user if different from the one who requested to change his email
    my $web_user  = $hub->user;
    my $user      = $login->user;
    $web_user->deauthorise if $web_user->user_id ne $user->user_id;

    if ($email eq $user->new_email) {
      $user->email($email);
      $user->save;

      # 'identity' is the email used for logging in to the site using a local login
      $login->identity($email) if $login->type eq 'local';
      $login->reset_salt_and_save;

      return $self->redirect_message(MESSAGE_EMAIL_CHANGED);
    }
  }

  return $self->redirect_message(MESSAGE_URL_EXPIRED, {'error' => 1});
}

1;