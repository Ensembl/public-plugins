package EnsEMBL::Web::Factory::Healthcheck;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Factory);

use EnsEMBL::Web::Proxy::Object;
use EnsEMBL::Web::Data::HcSessionView;

sub createObjects {
  my $self      = shift;
  my $release   = $self->param('release') ||  $self->species_defs->ENSEMBL_VERSION;
  my $max_session_for_release = EnsEMBL::Web::Data::HcSessionView->max_for_release($release);

  $self->DataObjects( new EnsEMBL::Web::Proxy::Object(
    'Healthcheck', {
        'max_session_for_release'  => $max_session_for_release,  # session data for a release
        'release'                  => $release,
    }, $self->__data
  ));

}

1;
