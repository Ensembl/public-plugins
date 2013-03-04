package EnsEMBL::Web::Configuration::Account;

use strict;

use EnsEMBL::Web::Tools::MethodMaker ('copy' => {
  'SECURE_PAGES'  => '_SECURE_PAGES',
  'populate_tree' => '_populate_tree'
});

sub SECURE_PAGES {
  return __PACKAGE__->_SECURE_PAGES, qw(OpenID);
}

sub populate_tree {
  my $self = shift;

  $self->_populate_tree(@_);

  if ($self->hub->user) {

    # page modified from openid buttons component to allow a logged in user to select another openid provider as an alternative login option
    $self->get_node('Preferences')->append($self->create_node('Details/AddLogin', 'Add Login', [
      'edit_details'      =>  'EnsEMBL::OpenID::Component::Account::Buttons'
    ], { 'no_menu_entry'  =>  1 }));

  } else {

    # modify login form for openid login options 
    $self->delete_node('Login');
    $self->create_node('Login', 'Login', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'login'       =>  'EnsEMBL::Users::Component::Account::Login',
      'openid'      =>  'EnsEMBL::OpenID::Component::Account::Buttons'
    ], { 'availability' => 1 });

    # modify registration form for openid login options
    $self->delete_node('Register');
    $self->create_node('Register', 'Register', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'register'    =>  'EnsEMBL::Users::Component::Account::Register',
      'openid'      =>  'EnsEMBL::OpenID::Component::Account::Buttons'
    ], { 'availability' => 1 });

    # page displayed when user logs in to the site for the first time via openid to ask him some extra registration info
    $self->create_node('OpenID/Register', '', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'register'    =>  'EnsEMBL::OpenID::Component::Account::Register'
    ], { 'no_menu_entry' => 1  });

    # page displayed when user logs in to the site for the first time via openid to ask provide email address if he already has an account on ensembl
    $self->create_node('OpenID/LinkExisting', '', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'register'    =>  'EnsEMBL::OpenID::Component::Account::LinkExisting'
    ], { 'no_menu_entry' => 1  });

    # page displayed to ask the user to choose a way to authenticate his account when user logs in to the site for the first time via openid to asks email to link existing account
    $self->create_node('OpenID/Authenticate', '', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'register'    =>  'EnsEMBL::OpenID::Component::Account::Authenticate'
    ], { 'no_menu_entry' => 1  });

    # OpenID related commands - command to make request to openid provider, command to handle response from the provider, command to add a new openid user
    $self->create_node( "OpenID/$_", '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::OpenID::Command::Account::Add' }) for qw(Add Link);
  }

  # Openid resuest and response commands work both ways - user logged in or not (if your is logged it, its a request to add login)
  $self->create_node( "OpenID/$_",  '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::OpenID::Command::Account::$_" }) for qw(Request Response);
}

1;
