package EnsEMBL::Users::Component::Account::ForgotPassword;

### Create a form for the user to be able to request for lost password

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return 'Forgot Password';
}

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $content = $self->get_wrapper_div;
  my $form    = $content->append_child($self->new_form({'action' => $hub->url({'action' => 'ResetPassword'})}));

  $form->add_notes(sprintf q(<p>If you have lost your password, please enter your email address used while registering with %s and we will send you an email to retrieve your password.</p>), $hub->species_defs->ENSEMBL_SITETYPE);
  $form->add_field({'type'  => 'Email',  'name'  => 'email',   'label' => 'Email', 'required'  => 'yes'});
  $form->add_button({'type' => 'Submit', 'name'  => 'submit',  'value' => 'Send',  'class'     =>'modal_link'});

  return $content->render;
}

1;