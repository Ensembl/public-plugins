package EnsEMBL::WebAdmin::Controller::Command::Web::AdminHome;

use strict;
use warnings;

use Class::Std;

use base 'EnsEMBL::WebAdmin::Controller::Command::Web';

{

sub BUILD {
  my ($self, $ident, $args) = @_;
  my $SD = $self->get_species_defs;
  $self->add_filter('EnsEMBL::Web::Controller::Command::Filter::Member', {'group_id' => $SD->ENSEMBL_WEBADMIN_ID});
  $self->add_filter('EnsEMBL::Web::Controller::Command::Filter::LoggedIn'); 
}

sub render {
  my ($self, $action) = @_;
  $self->set_action($action);
  if ($self->filters->allow) {
    $self->render_page;
  } else {
    $self->render_message;
  }
}

sub render_page {
  my $self = shift;

  my $webpage= new EnsEMBL::Web::Document::WebPage(
    'renderer'   => 'Apache',
    'outputtype' => 'HTML',
    'scriptname' => 'web/admin_home',
    'objecttype' => 'User',
  );

  if( $webpage->has_a_problem() ) {
    $webpage->render_error_page( $webpage->problem->[0] );
  } else {
    foreach my $object( @{$webpage->dataObjects} ) {
      $webpage->configure( $object, 'admin_home', 'admin_menu' );
    }
    $webpage->action();
  }

}

}

1;
