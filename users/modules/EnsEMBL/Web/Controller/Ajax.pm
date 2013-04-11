package EnsEMBL::Web::Controller::Ajax;

use strict;

use EnsEMBL::Web::Document::Element::AccountLinks;

sub accounts_dropdown {
  my ($self, $hub) = @_;
  
  print EnsEMBL::Web::Document::Element::AccountLinks->new({'hub' => $hub})->content_ajax;
}

1;
