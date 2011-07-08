package EnsEMBL::Web::Configuration::AnalysisDescription;

use strict;

use base qw(EnsEMBL::Web::Configuration::Production);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Display';
}

sub short_caption { 'Analysis Desc'; }
sub caption       { 'Analysis Description'; }

1;