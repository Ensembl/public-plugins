package EnsEMBL::Users::Component::Account::Login;

### Component for User Login page

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub caption {
  return sprintf 'Login to %s', shift->site_name;
}

sub content {
  my $self      = shift;
  my $object    = $self->object;
  my $hub       = $self->hub;
  my $content   = $self->get_wrapper_div;
  my $referer   = $hub->param('then') || $hub->referer->{'absolute_url'};
  $referer      = $hub->species_defs->ENSEMBL_BASE_URL.$hub->current_url if $hub->action ne 'Login'; # if ended up on this page from some 'available for logged-in user only' page for Account type

  my $form      = $content->append_child($self->new_form({'id' => 'login', 'action' => $hub->url({qw(action Authenticate)})}));

  $form->add_hidden({'name'  => 'then', 'value' => $referer}) if $referer;
  $form->add_field([
    {'type'  => 'Email',    'name'  => 'email',     'label' => 'Email',     'required' => 'yes'},
    {'type'  => 'Password', 'name'  => 'password',  'label' => 'Password',  'required' => 'yes'},
    {'type'  => 'Submit',   'name'  => 'submit',    'value' => 'Log in',    'notes'    => sprintf('<p><a href="%s" class="modal_link">Forgot password</a> | <a href="%s" class="modal_link">Register</a></p>',
      $hub->url({qw(type Account action LostPassword)}),
      $hub->url({qw(type Account action Register)})
    )}
  ]);

  return $self->render_message . $content->render . $self->render_openid_buttons;
}

1;