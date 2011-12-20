package EnsEMBL::Web::Configuration::HelpLink;

use strict;

use base qw(EnsEMBL::Web::Configuration::HelpRecord);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Display';
}

1;