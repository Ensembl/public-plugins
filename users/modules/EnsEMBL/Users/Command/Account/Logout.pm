package EnsEMBL::Users::Command::Account::Logout;

### Command to clear user cookies
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $hub     = $self->hub;

  # clears cookies & saved user object
  $hub->user->deauthorise;

  return $self->ajax_redirect($hub->type eq 'Account' ? $hub->url({'action' => 'Login'}) : $hub->referer->{'absolute_url'});
}

1;