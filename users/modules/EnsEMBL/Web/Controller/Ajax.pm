package EnsEMBL::Web::Controller::Ajax;

use strict;

use EnsEMBL::Web::Document::Element::AccountLinks;
use EnsEMBL::Users::Component::Account::Login;

sub accounts_dropdown {
  my ($self, $hub) = @_;
  
  print EnsEMBL::Web::Document::Element::AccountLinks->new({'hub' => $hub})->content_ajax;

  if (!$hub->user) {
# TODO
#    print EnsEMBL::Users::Component::Account::Login->new($hub)->login_form(1)->render;
  }
}

1;
