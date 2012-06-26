package EnsEMBL::Users::Component::Account::Password::Lost;

### Create a form for the user to be able to request for lost password
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return 'Lost Password';
}

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $content   = $self->wrapper_div;
  my $form      = $content->append_child($self->new_form({'action' => $hub->url({'action' => 'Password', 'function' => 'Retrieve'})}));
  my $ex_email  = $hub->param('email');

  $form->add_notes(sprintf q(<p>If you have lost your password, please enter your email address used while registering to %s and we will send you an email to retrieve your password.</p>), $self->site_name);
  $form->add_field({'type'  => 'Email',  'name'  => 'email',   'label' => 'Email', 'required'  => 'yes', $ex_email ? ('value' => $ex_email) : ()});
  $form->add_button({'type' => 'Submit', 'name'  => 'submit',  'value' => 'Send',  'class'     => 'modal_link'});

  return $content->render;
}

1;