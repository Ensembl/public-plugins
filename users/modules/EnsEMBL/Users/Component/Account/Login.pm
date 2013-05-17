package EnsEMBL::Users::Component::Account::Login;

### Component for User Login page
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return sprintf 'Login to %s', shift->site_name;
}

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $then_param  = $self->get_then_param;
  my $form        = $self->new_form({'id' => 'login', 'action' => {qw(action User function Authenticate)}});
  my $ex_email    = $hub->param('email');

  $form->add_hidden({'name'  => 'then', 'value' => $then_param}) if $then_param;
  $form->add_field([
    {'type'  => 'Email',    'name'  => 'email',     'label' => 'Email',     'required' => 'yes', $ex_email ? ('value' => $ex_email) : ()},
    {'type'  => 'Password', 'name'  => 'password',  'label' => 'Password',  'required' => 'yes'},
    {'type'  => 'Submit',   'name'  => 'submit',    'value' => 'Log in',    'notes'    => sprintf('<p><a href="%s" class="modal_link">Lost password</a> | <a href="%s" class="modal_link">Register</a></p>',
      $hub->url({qw(action Password function Lost), $ex_email ? ('email' => $ex_email) : ()}),
      $hub->url({qw(action Register)})
    )}
  ]);

  return $self->js_section({'subsections' => [ $form->render ]});
}

1;