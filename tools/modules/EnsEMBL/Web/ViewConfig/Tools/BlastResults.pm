package EnsEMBL::Web::ViewConfig::Tools::BlastResults;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift; 
  $self->add_image_config('hsp_query_plot', 'Vkaryoblast', 'nodas');
}

sub form {
  my $self = shift;

}

1;
