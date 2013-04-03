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

  # redirect to the right page depending upon the referer
  my $referer = $hub->referer;

  return $self->ajax_redirect($referer->{'external'} || $referer->{'ENSEMBL_TYPE'} eq 'Account' ? '/' : $referer->{'absolute_url'}, {}, '', 'page');
}

1;