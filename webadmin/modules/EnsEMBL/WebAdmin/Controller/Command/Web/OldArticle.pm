package EnsEMBL::WebAdmin::Controller::Command::Web::OldArticle;

use strict;
use warnings;

use Class::Std;
use EnsEMBL::Web::Object::Data::Article;

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
  my $data = EnsEMBL::Web::Object::Data::Article->new();
  $interface->data($data);
  $interface->discover;

  ## Customization
  ## Page components
  $interface->default_view('select_to_edit');
  $interface->script_name($self->get_action->script_name);

  ## Values for lookups
  my @help_cats;
  my $cats = EnsEMBL::Web::Object::Data::find_all('EnsEMBL::Web::Object::Data::Category');
  foreach my $cat (@$cats) {
    push @help_cats, {'name'=> $cat->name, 'value' => $cat->id};
  }
  $interface->customize_element('category_id', 'values', \@help_cats);
  $interface->customize_element('content', 'rows', '30');
  $interface->customize_element('content', 'cols', '120');

## Form elements
  $interface->element_order('title', 'keyword', 'category_id', 'status', 'content');

  #$interface->multi(0);
  $interface->dropdown(1);
  $interface->option_columns('title');
  $interface->option_order({'column'=>'title','order'=>'ASC'});


  ## Render page or munge data, as appropriate
  $webpage->process($interface);
}

}

1;
