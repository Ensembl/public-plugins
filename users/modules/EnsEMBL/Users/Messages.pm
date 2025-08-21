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

package EnsEMBL::Users::Messages;

### @usage
### use EnsEMBL::Users::Messages qw(ALL);                     # is same as use EnsEMBL::Users::Messages; # will include all the message constants, but not the get_message method
### use EnsEMBL::Users::Messages qw(get_message);             # will only include the get_message method, no message constants
### use EnsEMBL::Users::Messages qw(ALL get_message);         # will include all message constants and the get_message method
### use EnsEMBL::Users::Messages qw(MESSAGE_PASSWORD_WRONG);  # will only include only the specified message constant - could be multiple

use strict;
use warnings;

use HTML::Entities qw(encode_entities);
use Digest::MD5 qw(md5_hex);

my %MESSAGES = (
  MESSAGE_OPENID_CANCELLED      => sub { sprintf('Your request to login via %s was cancelled', encode_entities($_[0]->param('provider') || 'OpenID')) },
  MESSAGE_OPENID_INVALID        => sub { '_message__OPENID_INVALID' },
  MESSAGE_OPENID_SETUP_NEEDED   => sub { '_message__OPENID_SETUP_NEEDED' },
  MESSAGE_OPENID_ERROR          => sub { 'OpenID error', sprintf('<p>An error happenned while making OpenID request.</p><p>Error summary: %s</p>', encode_entities($_[0]->param('oerr') || '')) },
  MESSAGE_OPENID_EMAIL_MISSING  => sub { '_message__OPENID_EMAIL_MISSING' },
  MESSAGE_EMAIL_NOT_FOUND       => sub { 'Email not found', sprintf('The email address provided is not recognised. Please try again with a different email or <a href="%s">register</a> here if you are a new user.', encode_entities($_[0]->url({'type' => 'Account', 'action' => 'Register', 'email' => $_[0]->param('email') || ''}))) },
  MESSAGE_PASSWORD_WRONG        => sub { 'Wrong password', 'The password provided is invalid. Please try again.' },
  MESSAGE_PASSWORD_INVALID      => sub { 'Invalid password', 'Password needs to be atleast 6 characters long.' },
  MESSAGE_PASSWORD_MISMATCH     => sub { 'Password mismatch', 'The passwords do not match. Please try again.' },
  MESSAGE_PASSWORD_CHANGED      => sub { 'Password saved', 'New password has been saved successfully. Please login with the new password.' },
  MESSAGE_ALREADY_REGISTERED    => sub { sprintf('The email address provided seems to be already registered. Please try to login with the email, or request to <a href="%s">retrieve your password</a> if you have lost one.', $_[0]->url({'action' => 'Password', 'function' => 'Lost', 'email' => $_[0]->param('email') || ''})) },
  MESSAGE_VERIFICATION_FAILED   => sub { 'Verification failed', 'The email address could not be verified.' },
  MESSAGE_VERIFICATION_PENDING  => sub { 'Verification pending', 'The email address has yet not been verified.' },
  MESSAGE_EMAIL_INVALID         => sub { 'Invalid email', 'Please enter a valid email address' },
  MESSAGE_EMAILS_INVALID        => sub { 'Invalid email address', sprintf('Following email address(es) are not valid: %s', encode_entities($_[0]->param('invalids') || '')) },
  MESSAGE_NAME_MISSING          => sub { 'Please provide a name' },
  MESSAGE_CONSENT_REQUIRED      => sub { 'Please tick the privacy policy consent box if you wish to register.'},
  MESSAGE_ACCOUNT_PENDING       => sub { sprintf(q(Your account has been registered but not yet activated. <a href="%s">Resend activation email</a> or <a href="/Help/Contact">contact our helpdesk</a> if you need further assistance.), 
    $_[0]->url({'action' => 'User', 'function' => 'Resend', 'email' => $_[0]->param('email') || ''})) },
  MESSAGE_ACCOUNT_BLOCKED       => sub { 'Your account seems to be blocked. Please <a href="/Help/Contact">contact our helpdesk</a> if you require help.' },
  MESSAGE_ACCOUNT_DISABLED      => sub { 'Your account seems to be disabled. Please <a href="/Help/Contact">contact our helpdesk</a> if you require help.' },
  MESSAGE_VERIFICATION_SENT     => sub { sprintf(q(A verification email has been sent to the email address '%s'. Please go to your inbox and click on the link provided in the email.), encode_entities($_[0]->param('email'))) },
  MESSAGE_VERIFICATION_NOT_SENT => sub { 'Sorry, there was a problem with our mail server. Please contact our helpdesk at helpdesk@ensembl.org to request an activation code.' },
  MESSAGE_PASSWORD_EMAIL_SENT   => sub { sprintf(q(An email has been sent to the email address '%s'. Please go to your inbox and follow the instructions to reset your password provided in the email.), encode_entities($_[0]->param('email'))) },
  MESSAGE_PASSWORD_EMAIL_NOT_SENT => sub { 'Sorry, there was a problem with our mail server. Please contact our helpdesk at helpdesk@ensembl.org for assistance.' },
  MESSAGE_EMAIL_CHANGED         => sub { sprintf(q(Your email address on our records has been successfully changed. Please <a href="%s">%s</a> to continue.), $_[0]->user ? ($_[0]->PREFERENCES_PAGE, 'click here') : ($_[0]->url({qw(type Account action Login)}), 'login')) },
  MESSAGE_CANT_DELETE_LOGIN     => sub { 'You can not delete the only login option you have to access your account.' },
  MESSAGE_GROUP_NOT_FOUND       => sub { 'Sorry, we could not find the specified group. Either the group does not exist or is inactive or is inaccessible to you for the action selected.' },
  MESSAGE_GROUP_INACTIVE        => sub { 'Group inactive', 'This group is inactive. To perform the action selected, please activate the group first.'},
  MESSAGE_NO_GROUP_SELECTED     => sub { 'No group selected', 'Please select a group.' },
  MESSAGE_GROUP_INVITATION_SENT => sub { sprintf(q{Invitation for the group sent successfully to the following email(s): %s}, encode_entities($_[0]->param('emails'))) },
  MESSAGE_NO_BOOKMARK_SELECTED  => sub { 'No bookmark selected', 'Please select a bookmark.' },
  MESSAGE_CANT_DEMOTE_ADMIN     => sub { 'Not allowed', 'Sorry, you can not demote yourself as you seem to be the only administrator of this group.' },
  MESSAGE_BOOKMARK_NOT_FOUND    => sub { 'Bookmark not found', 'Sorry, we could not find the specified bookmark.' },
  MESSAGE_CANT_DELETE_BOOKMARK  => sub { 'Not allowed', 'You do not seem to have the right to delete this bookmark.' },
  MESSAGE_NO_EXISTING_ACCOUNT   => sub { sprintf(q(No existing account was found for the email address provided. Please verify the email address again, or to create a new account, please <a href="%s">click here</a>), $_[0]->url({'action' => 'OpenID', 'function' => 'Register', 'code' => $_[0]->param('code') || ''})) },
  MESSAGE_LOGIN_ALREADY_TAKEN   => sub { 'Could not add login', 'Sorry, this login option already exists for another user account.' },
  MESSAGE_LOGIN_ALREADY_LINKED  => sub { 'Login option already added', 'You already seem to have linked this login option to your account.' },
  MESSAGE_URL_EXPIRED           => sub { 'URL expired or invalid', 'The link you clicked to reach here has been expired or is invalid.' },
  MESSAGE_UNKNOWN_ERROR         => sub { 'Unknown error', 'An unknown error occurred. Please try again or <a href="/Help/Contact">contact our help desk</a>.' },
  MESSAGE_NON_LATIN_CHARS      => sub { 'Invalid characters', 'Please use only <a href="https://en.wikipedia.org/wiki/Windows-1252">Latin characters</a> in the input form.' }
);

my %CODES = map { $_ => substr(md5_hex($_), 0, 8) } keys %MESSAGES;

sub import {
  my $class     = shift;
  my $caller    = caller;
  my %includes  = map { $_ => 1 } @_;

  {
    no strict qw(refs);

    if ($includes{'get_message'}) {
      *{"${caller}::get_message"} = sub {
        my ($code, $hub) = @_;
        my $constant = { reverse %CODES }->{$code || ''};
        return $MESSAGES{$constant || 'MESSAGE_UNKNOWN_ERROR'}->($hub);
      };
    }

    foreach my $message_constant (grep { !@_ || $includes{'ALL'} || $includes{$_} } keys %MESSAGES) {
      *{"${caller}::${message_constant}"} = sub { return $CODES{$message_constant}; };
    }
  }
}

1;
