package EnsEMBL::Web::Configuration::Variation;

use strict;

sub modify_tree {
  my $self   = shift;

  ## Hide this node if not configured, as it's external data
  my $external = $self->get_node('ExternalData');
  if ($external && $self->hub->species_defs->LOVD_URL) {
    $external->append($self->create_node('LOVD', 'LOVD',
      [qw( lovd EnsEMBL::Web::Component::Variation::LOVD )],
      { 'availability' => 1 }
    ));
  }

}

1;
