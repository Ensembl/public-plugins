package EnsEMBL::Users::Component::Account::Register;

### Component for new user Registeration page

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return sprintf 'Register with %s', shift->site_name;
}

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $content = $self->get_wrapper_div;
  my $form    = $content->append_child($self->new_form({'action' => $hub->url({'action' => 'AddUser'})}));
  my $lists   = $hub->species_defs->SUBSCRIPTION_EMAIL_LISTS;

  $form->add_field({
    'label'     => 'Name',
    'name'      => 'name',
    'type'      => 'string',
    'required'  => 1,
  });

  $form->add_field({
    'label'     => 'Email Address',
    'name'      => 'email',
    'type'      => 'email',
    'required'  => 1,
    'notes'     => sprintf("You'll use this to log in to %s.", $self->site_name),
  });

  $form->add_field([ map {'type' => 'honeypot', 'name' => lc $_, 'label' => $_}, qw(Surname Address) ]); # honeypot fields for catching bots

  $form->add_field({
    'label'     => 'Organisation',
    'name'      => 'organisation',
    'type'      => 'string',
  });

  $form->add_field({
    'label'   => 'Ensembl news list subscription',
    'type'    => 'checklist',
    'name'    => 'subscription',
    'notes'   => 'Tick the box corresponding to the email list you would wish to subscribe to',
    'values'  => [ map {'value' => $_, 'caption' => $_, 'checked' => 1}, @$lists ]
  }) if @$lists;

  $form->add_button({'value' => 'Register'});

  return $content->render . $self->render_openid_buttons;
}

1;