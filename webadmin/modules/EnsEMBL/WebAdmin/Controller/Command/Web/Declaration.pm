package EnsEMBL::WebAdmin::Controller::Command::Web::Declaration;

use strict;
use warnings;

use Class::Std;
use EnsEMBL::Web::Object::Data::NewsItem; 
use EnsEMBL::Web::Object::Data::Species; 

use base 'EnsEMBL::Web::Controller::Command';

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
  
  ## This script needs access to SpeciesDefs so it can filter on current release
  my $SD = $EnsEMBL::Web::RegObj::ENSEMBL_WEB_REGISTRY->species_defs;
  my $current = $SiteDefs::VERSION;

  my $webpage = EnsEMBL::Web::Document::Interface::simple('News');

  ## Create interface object, which controls the forms
  my $interface = EnsEMBL::Web::Interface::InterfaceDef->new();
  my $data = EnsEMBL::Web::Object::Data::NewsItem->new();
  $interface->data($data);
  $interface->discover;

  ## Add any custom elements
  $interface->default_view('select_to_edit');
  $interface->script_name($self->get_action->script_name);

  $interface->element('species_tip', {'type' => 'Information', 'value' => 'Note: for items that apply to all species, leave the checkboxes blank!'});
  $interface->element('release_id', {'type' => 'NoEdit', 'label' => 'Release', 'value' => $current});
  $interface->element('title', {'type' => 'NoEdit'});
  $interface->element('content', {'type' => 'NoEdit'});

  ## Set lookup list parameters
  #$interface->multi(0);
  $interface->dropdown(1);
  $interface->option_columns('title', 'status');
  $interface->option_order('title');
  $interface->record_filter('release_id', $current);

  $interface->show_history(1);

  ## Basic configuration
  #$interface->element_order('release_id', 'species_tip', 'species_id', 'title', 'content', 'news_category_id', 'priority', 'status');
  $interface->element_order('release_id', 'declaration', 'notes', 'title', 'content', 'status');

  ## Render page or munge data, as appropriate
  $webpage->process($interface);
  #$webpage->process($interface, 'EnsEMBL::Web::Configuration::Interface::News');
}


}

1;
