package EnsEMBL::Users::Component::Account::Register;

### Component for new user Registeration page

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $content = $self->dom->create_element('div');
  my $form    = $content->append_child('div', {'class' => 'local-loginregister'})->append_child($self->new_form({'action' => $hub->url({'action' => 'AddUser'})}));
  my $fset    = $form->add_fieldset(sprintf('Register with %s', $self->site_name));
  my $lists   = $hub->species_defs->SUBSCRIPTION_EMAIL_LISTS;

  $fset->add_field({
    'label'     => 'Name',
    'name'      => 'name',
    'type'      => 'string',
    'required'  => 1,
  });

  $fset->add_field({
    'label'     => 'Email Address',
    'name'      => 'email',
    'type'      => 'email',
    'required'  => 1,
    'notes'     => sprintf("You'll use this to log in to %s.", $self->site_name),
  });

  $fset->add_field([ map {'type' => 'honeypot', 'name' => lc $_, 'label' => $_}, qw(Surname Address) ]); # honeypot fields for catching bots

  $fset->add_field({
    'label'     => 'Organisation',
    'name'      => 'organisation',
    'type'      => 'string',
  });

  $fset->add_field({
    'label'   => 'Ensembl news list subscription',
    'type'    => 'checklist',
    'name'    => 'subscription',
    'notes'   => 'Tick the box corresponding to the email list you would wish to subscribe to',
    'values'  => [ map {'value' => $_, 'caption' => $_, 'checked' => 1}, @$lists ]
  }) if @$lists;

  $fset->add_button({'value' => 'Register'});

  $content->append_child($self->openid_buttons);

  return $content->render;
}

1;