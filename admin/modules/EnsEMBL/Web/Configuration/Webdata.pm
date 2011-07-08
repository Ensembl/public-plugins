package EnsEMBL::Web::Configuration::Webdata;

use strict;

use base qw(EnsEMBL::Web::Configuration::Production);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Display';
}

sub short_caption { 'Webdata'; }
sub caption       { 'Webdata'; }

1;