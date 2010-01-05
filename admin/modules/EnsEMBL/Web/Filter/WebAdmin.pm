package EnsEMBL::Web::Filter::WebAdmin;

use strict;
use warnings;

use EnsEMBL::Web::RegObj;
use EnsEMBL::Web::Registry;

use base qw(EnsEMBL::Web::Filter);

sub init {
  my $self = shift;

  $self->redirect = '/Account/Login?popup=no';
  $self->messages = {
    not_member => 'You are either not logged in or you are not a member of this group. If you think this is incorrect, please contact the web team.',
  };
}


sub catch {
  my $self = shift;
  my $user = $EnsEMBL::Web::RegObj::ENSEMBL_WEB_REGISTRY->get_user;
  unless ($user && $user->is_member_of($self->object->species_defs->ENSEMBL_WEBADMIN_ID)) {
    $self->error_code = 'not_member';
  }
}

1;
