package EnsEMBL::Users::Command::Account::Details::ChangeEmail;

### Command to change the user email - user lands on this page after clicking on the link sent to him via email for the purpose of verifying his new email address
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;

  my $login     = $object->fetch_login_from_url_code;
  my $fields    = $self->validate_fields({'email' => $hub->param('email')});

  return $self->redirect_message($object->get_message_code('MESSAGE_UNKNOWN_ERROR'), {'error' => 1}) if !$login || $fields->{'invalid'};

  # logout the logged-in user if different from the one who requested to change his email
  my $web_user  = $hub->user;
  my $user      = $login->user;
  $web_user->deauthorise if $web_user->user_id ne $user->user_id;

  $user->email($fields->{'email'});
  $user->save;

  # 'identity' is the email used for logging in to the site using a local login
  $login->identity($fields->{'email'}) if $login->type eq 'local';
  $login->reset_salt_and_save;

  return $self->redirect_message($object->get_message_code('MESSAGE_EMAIL_CHANGED'));
}

1;