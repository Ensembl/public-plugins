package EnsEMBL::Web::Filter::WebAdmin;

use strict;

use base qw(EnsEMBL::Web::Filter);

sub init {
  my $self = shift;

  $self->redirect = '/Account/Login?popup=no';
  $self->messages = {
    not_member => 'These pages are restricted to members of the Ensembl webadmin group. If you require access, please contact the web team.',
  };
}


sub catch {
  my $self = shift;
  my $hub  = $self->hub;
  my $user = $hub->user;
  unless ($user && $user->is_member_of($hub->species_defs->ENSEMBL_WEBADMIN_ID)) {
    $self->error_code = 'not_member';
  }
}

1;
