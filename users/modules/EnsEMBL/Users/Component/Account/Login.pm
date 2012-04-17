package EnsEMBL::Users::Component::Account::Login;

### Component for User Login page

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self      = shift;
  my $object    = $self->object;
  my $hub       = $self->hub;
  my $content   = $self->dom->create_element('div');
  my $referer   = $hub->param('then') || $hub->referer->{'absolute_url'};
  $referer      = $hub->species_defs->ENSEMBL_BASE_URL.$hub->current_url if $hub->action ne 'Login'; # if ended up on this page from some 'available for logged-in user only' page for Account type

  my $form      = $content->append_child('div', {'class' => 'local-loginregister'})->append_child($self->new_form({'id' => 'login', 'action' => $hub->url({qw(action Authenticate)})}));
  my $fieldset  = $form->add_fieldset;

  $fieldset->add_hidden({'name'  => 'then', 'value' => $referer}) if $referer;
  $fieldset->add_field([
    {'type'  => 'Email',    'name'  => 'email',     'label' => 'Email',     'required' => 'yes'},
    {'type'  => 'Password', 'name'  => 'password',  'label' => 'Password',  'required' => 'yes'},
    {'type'  => 'Submit',   'name'  => 'submit',    'value' => 'Log in',    'notes'    => sprintf('<p><a href="%s" class="modal_link">Forgot password</a> | <a href="%s" class="modal_link">Register</a></p>',
      $hub->url({qw(type Account action LostPassword)}),
      $hub->url({qw(type Account action Register)})
    )}
  ]);

  $content->append_child($self->openid_buttons);
  
  return sprintf('<h2>Login to %s</h2>%s', $self->site_name, $content->render);
}

1;