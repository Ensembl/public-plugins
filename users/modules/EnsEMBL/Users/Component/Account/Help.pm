package EnsEMBL::Users::Component::Account::Help;

use strict;

use base qw(EnsEMBL::Web::Component::Help::View);

sub content {
  my $self = shift;
  my $hub  = $self->hub;
  my %help = $hub->species_defs->multiX('ENSEMBL_HELP');
  
  $hub->param('id', $help{'Account'});
  
  return $self->SUPER::content;
}

1;
