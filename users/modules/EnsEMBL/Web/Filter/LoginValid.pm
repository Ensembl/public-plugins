package EnsEMBL::Web::Filter::LoginValid;

### Checks if a password matches the encrypted value stored in the database

use strict;

use EnsEMBL::Web::Tools::Encryption qw(encryptPassword);

use base qw(EnsEMBL::Web::Filter);

sub init {
  my $self = shift;
  $self->messages = {
    empty_email       => 'You did not supply an email. Please try again.',
    empty_password    => 'You did not supply a password. Please try again.',
    invalid_password  => sprintf('Sorry, the email address or password was
                              incorrect and could not be validated. Please try 
                              again.<br /><br />If you are unsure of your password,
                              <a href="%s" class="modal_link">click here to recover
                              lost passowrd</a>.', $self->hub->url({'type' => 'Account', 'action' => 'LostPassword'})
    )
  };
}

sub catch {
  my $self      = shift;
  my $hub       = $self->hub;
  my $user      = $self->object->rose_object;
  my $password  = $hub->param('password');

  $self->redirect   = sprintf('/Account/Login?then=%s', $hub->param('then'));
  $self->error_code = $hub->param('email') ? $password ? $user && $user->password eq encryptPassword($password, $user->salt) ? undef : 'invalid_password' : 'empty_password' : 'empty_email';
  # N.B. for security reasons, we do not distinguish between an invalid email address or password
}

1;