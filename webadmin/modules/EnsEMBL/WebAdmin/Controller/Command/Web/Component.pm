package EnsEMBL::WebAdmin::Controller::Command::Web::Component;

use strict;
use warnings;

use Class::Std;
use EnsEMBL::Web::Object::Data::Component;

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
  ## Create basic page object, so we can access CGI parameters
  my $webpage = EnsEMBL::Web::Document::Interface::simple('User');

  my $sd = EnsEMBL::Web::SpeciesDefs->new();

  ## Create interface object, which controls the forms
  my $interface = EnsEMBL::Web::Interface::InterfaceDef->new();
  my $data = EnsEMBL::Web::Object::Data::Component->new();
  $interface->data($data);
  $interface->discover;

  ## Customization

  ## Page components
  $interface->default_view('select_to_edit');
  $interface->script_name($self->get_action->script_name);

## Form elements
  $interface->customize_element('keyword', 'label', 'Component and method');
  $interface->customize_element('keyword', 'default', 'EnsEMBL::Web::Component::');
  $interface->element_order('keyword', 'content', 'status');

  #$interface->multi(0);
  $interface->dropdown(1);
  $interface->option_columns('word');
  $interface->option_order({'column'=>'word','order'=>'ASC'});


  ## Render page or munge data, as appropriate
  $webpage->process($interface);
}

}

1;
