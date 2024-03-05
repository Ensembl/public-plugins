=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Configuration::Account;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Configuration);

sub SECURE_PAGES {
  ## TODO
  ## @return List of url 'action' for all the pages that should be served over https
  return qw(Login);
}

sub set_default_action {
  my $self  = shift;
  my $hub   = $self->hub;
  $self->{'_data'}{'default'} = $hub->users_available ? $hub->user ? 'Preferences' : 'Login' : 'Down';
}

sub get_valid_action {
  ## @override
  ## Don't show 404, go to default action instead
  my $self    = shift;
  my $node_id = $self->SUPER::get_valid_action(@_);

  return $node_id eq 'Unknown' ? $self->default_action : $node_id;
}

sub user_tree { return 1; }

sub user_populate_tree {}

sub tree_cache_key {
  my ($self, $user, $session) = @_;

  ## Default trees for logged-in users and
  ## for non logged-in are defferent
  ## but we cache both:
  my $class = ref $self;
  my $hub   = $self->hub;
  my $key   = $hub->users_available
    ? $hub->user
      ? "::${class}::TREE::USER"
      : "::${class}::TREE"
    : "::${class}::TREE::NOUSERDB"
  ;

  ## If $user was passed this is for
  ## user_populate_tree (this user specific tree)
  $key .= '['. $user->id .']'
    if $user;

  return $key;
}

sub populate_tree {
  my $self      = shift;
  my $hub       = $self->hub;
  my $user      = $hub->user;
  my $action    = $hub->action;
  my $function  = $hub->function;
  my $object    = $self->object;

  if ($hub->users_available) {

    ## PAGES FOR LOGGED IN USER ONLY
    if ($user) {

      # main preferences page to view all settings with links to edit individual detail, group, bookmark etc
      my $preference_menu = $self->create_node('Preferences', 'Account Settings', [
        'message'           =>  'EnsEMBL::Users::Component::Account::Message',
        'notifications'     =>  'EnsEMBL::Users::Component::Account::Groups::Notifications',
        'view_details'      =>  'EnsEMBL::Users::Component::Account::Details::View',
        'view_groups'       =>  'EnsEMBL::Users::Component::Account::Groups::ViewAll',
        'view_bookmarks'    =>  'EnsEMBL::Users::Component::Account::Bookmark::View',
      ], { 'availability'   =>  1 });

      # page to display a form to edit user details - name, email etc
      $preference_menu->append($self->create_node('Details/Edit', 'Edit Details', [
        'edit_details'      =>  'EnsEMBL::Users::Component::Account::Details::Edit'
      ], { 'availability'   =>  1 }));

      # page to view a single group
      $preference_menu->append($self->create_node('Groups/View', 'View a group', [
        'message'           =>  'EnsEMBL::Users::Component::Account::Message',
        'view_group'        =>  'EnsEMBL::Users::Component::Account::Groups::View'
      ], { 'availability'   =>  1 }));

      # page to edit a group
      $preference_menu->append($self->create_node('Groups/Edit', 'Edit a group', [
        'message'           =>  'EnsEMBL::Users::Component::Account::Message',
        'edit_group'        =>  'EnsEMBL::Users::Component::Account::Groups::AddEdit'
      ], { 'availability'   =>  1 }));

      # page to create a new group
      $preference_menu->append($self->create_node('Groups/Add', 'Create new group', [
        'message'           =>  'EnsEMBL::Users::Component::Account::Message',
        'add_group'         =>  'EnsEMBL::Users::Component::Account::Groups::AddEdit'
      ], { 'availability'   =>  1 }));

      # page to list groups to be able to join an existing group
      $preference_menu->append($self->create_node('Groups/List', 'Join existing group', [
        'message'           =>  'EnsEMBL::Users::Component::Account::Message',
        'list_groups'       =>  'EnsEMBL::Users::Component::Account::Groups::List'
      ], { 'availability'   =>  1 }));

      # page to create a new group
      $preference_menu->append($self->create_node('Groups/Invite', 'Invite new members', [
        'message'           =>  'EnsEMBL::Users::Component::Account::Message',
        'add_group'         =>  'EnsEMBL::Users::Component::Account::Groups::Invite'
      ], { 'availability'   =>  1 }));

      # page to create a new group
      $preference_menu->append($self->create_node('Groups/ConfirmDelete', 'Delete group', [
        'add_group'         =>  'EnsEMBL::Users::Component::Account::Groups::ConfirmDelete'
      ], { 'no_menu_entry'  =>  1 }));

      # page to view all bookmarks
      $preference_menu->append($self->create_node('Bookmark/View', '', [
        'view_bookmarks'    =>  'EnsEMBL::Users::Component::Account::Bookmark::View',
      ], { 'availability'   =>  1, 'no_menu_entry' => 1 }));

      # page to edit a bookmark
      $preference_menu->append($self->create_node('Bookmark/Edit', 'Edit bookmark', [
        'edit_bookmark'     =>  'EnsEMBL::Users::Component::Account::Bookmark::AddEdit'
      ], { 'availability'   =>  1 }));

      # page to add a bookmark
      $preference_menu->append($self->create_node('Bookmark/Add', 'Create new bookmark', [
        'add_bookmark'      =>  'EnsEMBL::Users::Component::Account::Bookmark::AddEdit'
      ], { 'availability'   =>  1 }));

      # page to share a bookmark with a group
      $preference_menu->append($self->create_node('Share/Bookmark', 'Share bookmark', [
        'message'           =>  'EnsEMBL::Users::Component::Account::Message',
        'share_bookmark'    =>  'EnsEMBL::Users::Component::Account::Share::Bookmark'
      ], { 'availability'   =>  1 }));

      # commands to save and reset favourites species
      $self->create_node("Favourites/$_",   '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Favourites::$_" }) for qw(Save Reset);

      # command to clear user browsing history shown in tabs
      $self->create_node('ClearHistory',    '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::ClearHistory'   });

      # commands to save the edited user details and to remove any linked login account from the user account
      $self->create_node("Details/$_",      '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Details::$_"    }) for qw(Save RemoveLogin);

      # commands to save, use and remove a bookmark
      $self->create_node("Bookmark/$_",     '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Bookmark::$_"   }) for qw(Save Use Remove Share Copy);

      # commands to save, join, send invite for or delete a group
      $self->create_node("Group/$_",        '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Group::$_"      }) for qw(Save Join Invite Delete);

      # command to make changes to a membership object
      $self->create_node("Membership/$_",   '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Membership::$_" }) for (qw(Accept Decline BlockGroup Allow Ignore BlockUser Remove Unjoin Change Create));

      # page not actually used to login, but to do redirection to further appropriate page
      $self->create_node('Login',           '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::LoginRedirect'  });

    ## PAGES AVAILABLE ONLY WHEN NO USER LOGGED IN
    } else {

      # page to display login form and openid login options
      $self->create_node('Login', 'Login', [
        'message'     =>  'EnsEMBL::Users::Component::Account::Message',
        'login'       =>  'EnsEMBL::Users::Component::Account::Login',
      ], { 'availability' => 1 });

      # Don't show registration links if not on relevant site
      my $accounts_site = $hub->species_defs->ENSEMBL_ACCOUNTS_SITE;
      if (!$accounts_site) {
        # page to display registration form and openid login options
        $self->create_node('Register', 'Register', [
          'message'     =>  'EnsEMBL::Users::Component::Account::Message',
          'register'    =>  'EnsEMBL::Users::Component::Account::Register',
        ], { 'availability' => 1 });

        # page displayed for lost password request
        $self->create_node('Password/Lost', 'Lost Password', [
          'message'     =>  'EnsEMBL::Users::Component::Account::Message',
          'password'    =>  'EnsEMBL::Users::Component::Account::Password::Lost'
        ], { 'availability' => 1 });
      }

      # Command to add (register) a new user, and to authenticate an existing user
      $self->create_node( "User/$_",            '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::User::$_"           }) for qw(Add Authenticate);

      # Command to retrieve lost password
      $self->create_node( 'Password/Retrieve',  '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Password::Retrieve' });
    }

    ## PAGES AVAILABLE ALWAYS - INDEPENDENT OF WHETHER THE USER IS LOGGED IN OR NOT

    # page displayed for change password form
    $self->create_node('Password/Change', 'Change Password', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'password'    =>  'EnsEMBL::Users::Component::Account::Password::Change'
    ], { 'no_menu_entry' => 1 });

    # page displayed with a form to choose a password when user clicks on the link in his email to verify his email
    $self->create_node('Details/Confirm', '', [
      'message'       =>  'EnsEMBL::Users::Component::Account::Message',
      'confirmemail'  =>  'EnsEMBL::Users::Component::Account::Details::Confirm'
    ], { 'no_menu_entry' => 1 });

    # Mechanism for GDPR consent
    $self->create_node('Consent', 'Privacy Policy Consent', [
      'consent'    =>  'EnsEMBL::Users::Component::Account::Consent'
    ], { 'no_menu_entry' => 1 });
    $self->create_node('ConsentWarning', 'Account Disable Warning', [
      'consent'    =>  'EnsEMBL::Users::Component::Account::ConsentWarning'
    ], { 'no_menu_entry' => 1 });
    $self->create_node($_,  '',       [], { 'no_menu_entry' => 1,       'command' => "EnsEMBL::Users::Command::Account::$_"}) for qw(UpdateConsent DisableAccount);

    # page to display generic messages
    $self->create_node('Message', '', [
      'message'       =>  'EnsEMBL::Users::Component::Account::Message'
    ], { 'no_menu_entry' => 1 });

    # Command reached through link in an email to verify email address, command to change the email after the user clicks on the verification email sent to his new address
    $self->create_node("Details/$_",  '',       [], { 'no_menu_entry' => 1,       'command' => "EnsEMBL::Users::Command::Account::Details::$_"                  }) for qw(Verify ChangeEmail);

    # Command to confirm user account and save the newly choosen password (intentionally kept same as in Password/Save), command to save password after a password lost request or just a change password request
    $self->create_node($_,            '',       [], { 'no_menu_entry' => 1,       'command' => 'EnsEMBL::Users::Command::Account::Password::Save'               }) for qw(Confirmed Password/Save);

    # Help page to do with accounts
    $self->create_node('Help',   'Help', [ 'help' => 'EnsEMBL::Users::Component::Account::Help' ]);
    
    # Generic logout command
    $self->create_node('Logout', 'Logout', [], { 'no_menu_entry' => !$user,  'command' => 'EnsEMBL::Users::Command::Account::Logout', 'availability' => 1  });

  # IF USERDB IS DOWN
  } else {

    $self->create_node('Down', 'Down', [
      'down' => 'EnsEMBL::Users::Component::Account::Down'
    ], { 'no_menu_entry' => 1 });
  }
}

1;
