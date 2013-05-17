package EnsEMBL::Users::Component::Account::Details::Confirm;

### Component for the user to confirm his email and choose a password for login
### This page is shown when user clicks on a link from his email that was sent to him after he registered with ensembl locally
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_URL_EXPIRED);

use base qw(EnsEMBL::Users::Component::Account);

sub caption { return sprintf 'Register with %s', shift->site_name; }

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $login   = $object->fetch_login_from_url_code;

  return $self->render_message(MESSAGE_URL_EXPIRED, {'error' => 1}) unless $login;

  my $user    = $login->user;
  my $form    = $self->new_form({'action' => {qw(action Confirmed)}, 'csrf_safe' => 1});

  $form->add_hidden({'name' => 'code',    'value' => $login->get_url_code});
  $form->add_hidden({'name' => 'referer', 'value' => join '/', $hub->action, $hub->function});

  $form->add_field([
    {'label'  => 'Name',              'type' => 'noedit',   'value' => $login->name || $user->name, 'no_input'  => 1                                    },
    {'label'  => 'Email Address',     'type' => 'noedit',   'value' => $user->email,                'no_input'  => 1                                    },
    {'label'  => 'Password',          'type' => 'password', 'name'  => 'new_password_1',            'required'  => 1, 'notes' => 'at least 6 characters'},
    {'label'  => 'Confirm password',  'type' => 'password', 'name'  => 'new_password_2',            'required'  => 1                                    }
  ]);

  $form->add_button({'value' => 'Activate account'});

  return $self->js_section({'subsections' => [ $form->render ]});
}

1;
