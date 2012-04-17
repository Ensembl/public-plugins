package EnsEMBL::Users::Component::Account::ConfirmEmail;

### Component for user to confirm his email and choose a password for login

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $content = $self->dom->create_element('div', {'class' => 'local-loginregister'});
  my $login   = $object->get_login_from_url_code;

  return $self->render_message($object->MESSAGE_CONFIRMATION_FAILED, {'error' => 1}) unless $login;

  my $user    = $login->user;
  my $form    = $content->append_child($self->new_form({'action' => $hub->url({'action' => 'AddUser/Confirmed'})}));
  my $fset    = $form->add_fieldset(sprintf('Register with %s', $self->site_name));

  $fset->add_hidden({'name' => 'code', 'value' => $login->get_url_code});

  $fset->add_field([
    {'label'  => 'Name',              'type' => 'noedit',   'value' => $login->name || $user->name, 'no_input'  => 1                                    },
    {'label'  => 'Email Address',     'type' => 'noedit',   'value' => $user->email,                'no_input'  => 1                                    },
    {'label'  => 'Password',          'type' => 'password', 'name'  => 'password',                  'required'  => 1, 'notes' => 'at least 6 characters'},
    {'label'  => 'Confirm password',  'type' => 'password'  'name'  => 'confirm_password',          'required'  => 1                                    }
  ]);

  $fset->add_button({'value' => 'Activate account'});

  return $content->render;
}

1;