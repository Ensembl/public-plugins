package EnsEMBL::Users::Command::Account::Favourites::Reset;

use strict;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self = shift;
  my $hub  = $self->hub;
  $_->delete for @{$hub->user->specieslists};
  $self->ajax_redirect($hub->species_defs->ENSEMBL_BASE_URL);
}

1;
