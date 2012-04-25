package EnsEMBL::Users::Command::Account::VerifyEmail;

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self = shift;

  return $self->ajax_redirect($self->hub->url({'action' => 'Message', 'function' => $self->object->activate_login ? 'Verified' : 'VerificationFailed'}));
}

1;