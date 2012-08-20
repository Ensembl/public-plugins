package EnsEMBL::Users::Command::Account::ClearHistory;

use strict;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self    = shift;
  my $user    = $self->hub->user;
  my $object  = $self->hub->param('object');

  $_->delete for $object ? grep($_->object eq $object, @{$user->histories}) : @{$user->histories};
}

1;
