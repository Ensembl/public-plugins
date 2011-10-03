package EnsEMBL::Web::Filter::WebAdmin;

use strict;

use base qw(EnsEMBL::Web::Filter);

sub init {
  my $self = shift;
  my $sd   = $self->hub->species_defs;

  $self->messages = {
    restricted => sprintf('These pages are restricted to members of the %s webadmin group. If you require access, please contact the %1$s Web Team.', $sd->ENSEMBL_SITETYPE),
  };
}

sub catch {
  my $self = shift;
  my $hub  = $self->hub;
  my $user = $hub->user;
  my $sd   = $hub->species_defs;

  $self->redirect   = sprintf('%s%s%s', '/Account/Login?then=', $sd->ENSEMBL_BASE_URL, $hub->url);
  $self->error_code = 'restricted' unless $user && $user->is_member_of($sd->ENSEMBL_WEBADMIN_ID);
}

1;