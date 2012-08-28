package EnsEMBL::Users::Component::Account::Register;

### Component for new user Registeration page
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return sprintf 'Register with %s', shift->site_name;
}

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $content = $self->wrapper_div;
  my $form    = $content->append_child($self->new_form({'action' => $hub->url({qw(action User function Add)})}));

  $form->add_field({qw(type honeypot name title   label Title)});      # honeypot fields for catching bots
  $form->add_field({qw(type honeypot name surname label Surname)});

  $self->add_user_details_fields($form, {
    'email'       => $hub->param('email') || '',
    'name'        => $hub->param('name')  || '',
    'email_notes' => sprintf("You'll use this to log in to %s.", $self->site_name)
  });

  return $content->render;
}

1;