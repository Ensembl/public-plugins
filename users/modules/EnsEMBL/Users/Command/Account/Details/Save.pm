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

package EnsEMBL::Users::Command::Account::Details::Save;

### Command module to save details edited by the user
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_EMAIL_INVALID MESSAGE_NAME_MISSING MESSAGE_VERIFICATION_SENT);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $r_user  = $hub->user->rose_object;

  # validation
  my $fields = $self->validate_fields({ map {$_ => $hub->param($_) || ''} qw(email name) });
  if ($fields->{'invalid'}) {
    return $self->ajax_redirect($hub->url({
      'action'    => 'Details',
      'function'  => 'Edit',
      'err'       => $fields->{'invalid'} eq 'email' ? MESSAGE_EMAIL_INVALID : MESSAGE_NAME_MISSING
      map {$_     => $hub->param($_)} qw(email name organisation country)
    }));
  }

  # save details other than email - no html escaping is done while saving - it's done while displaying the text on browser
  $r_user->name($fields->{'name'});
  $r_user->country($hub->param('country'));
  $r_user->organisation($hub->param('organisation'));
  $r_user->save('user' => $r_user);

  # send verification email to the new email if email changed
  if ($fields->{'email'} ne $r_user->email) {
    $r_user->new_email($fields->{'email'});
    $r_user->save;
    $self->mailer->send_change_email_confirmation_email($r_user->get_local_login || shift(@{$r_user->find_logins('query' => ['status' => 'active'])}), $fields->{'email'});
    return $self->redirect_message(MESSAGE_VERIFICATION_SENT, {'email' => $fields->{'email'}});
  }

  return $self->ajax_redirect($hub->PREFERENCES_PAGE);
}

1;
