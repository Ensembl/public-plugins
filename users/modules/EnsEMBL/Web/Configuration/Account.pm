package EnsEMBL::Web::Configuration::Account;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub get_valid_action {
  my $self = shift;
  return $_[0] if $_[0] eq 'SetCookie';
  return $self->SUPER::get_valid_action( @_ );
}

sub set_default_action {
  my $self = shift;
  my $user = $self->hub->user;
  if ($user && $user->id) {
    $self->{'_data'}{'default'} = 'Links';
  } else {
    $self->{'_data'}{'default'} = 'Login';
  }
}

sub user_tree { return 1; }

sub user_populate_tree {

  my $self = shift;
  my $hub = $self->hub;  

  if (my $user = $hub->user) {

  }
}



#     my $settings_menu = $self->create_submenu( 'Settings', 'Manage Saved Settings' );
# 
#     $settings_menu->append(
#       $self->create_node( 'Bookmark/List', "Bookmarks ([[counts::bookmarks]])", [],
#         { 'command' => 'EnsEMBL::Web::Command::Account::Interface::Bookmark',
#           'availability' => 1, 'concise' => 'Bookmarks' },
#       )
#     );
# 
#     ## Control panel fixes - custom data section is species-specific
#     my $species = $hub->species;
#     $species = '' if $species !~ /_/;
#     $species = $hub->species_defs->ENSEMBL_PRIMARY_SPECIES unless $species;
#     
#     $settings_menu->append(
#       $self->create_node( 'UserData', "Custom data ([[counts::userdata]])",
#         [], { 'availability' => 1, 'url' => $hub->species_path($species).'/UserData/ManageData', 'raw' => 1 },
#       )
#     );
# 
#     $settings_menu->append($self->create_node( 'Annotation/List', "Annotations ([[counts::annotations]])",
#     [], { 'command' => 'EnsEMBL::Web::Command::Account::Interface::Annotation',
#         'availability' => 1, 'concise' => 'Annotations' }
#     ));
#     $settings_menu->append(
#       $self->create_node( 'Newsfilter/List', "News Filters ([[counts::news_filters]])", [],
#         { 'command' => 'EnsEMBL::Web::Command::Account::Interface::Newsfilter', 
#           'availability' => 1, 'concise' => 'News Filters' },
#       )
#     );
# 
#     my $groups_menu = $self->create_submenu( 'Groups', 'Groups' );
#     
#     $groups_menu->append(
#       $self->create_node( 'MemberGroups', "Subscriptions ([[counts::member]])",
#         [qw(
#           groups   EnsEMBL::Web::Component::Account::MemberGroups
#           details  EnsEMBL::Web::Component::Account::MemberDetails
#         )],
#         { 'availability' => 1, 'concise' => 'Subscriptions' }
#       )
#     );
#     
#     $groups_menu->append(
#       $self->create_node( 'Group/List', "Administrator ([[counts::admin]])", [],
#         { 'availability' => 1, 'concise' => 'Administrator',
#           'command' => 'EnsEMBL::Web::Command::Account::Interface::Group' },
#       )
#     );
# 
#     $groups_menu->append(
#       $self->create_node( 'Group/Add', "Create a New Group",
#         [],
#         { 'availability' => 1, 'concise' => 'Create a Group', 
#           'command' => 'EnsEMBL::Web::Command::Account::Interface::Group', }
#       )
#     );
#     
#     ## Add "invisible" nodes used by interface but not displayed in navigation
#     ## 1. User records
#     $self->create_node( 'Annotation', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::Annotation',
#         'filters' => [qw(Owner)]}
#     );
#     $self->create_node( 'Bookmark', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::Bookmark',
#         'filters' => [qw(Owner)]}
#     );
#     $self->create_node( 'UseBookmark', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::UseBookmark',
#         'filters' => [qw(Owner)]}
#     );
#     $self->create_node( 'Configuration', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Configuration',
#         'filters' => [qw(Owner)]}
#     );
#     $self->create_node( 'LoadConfig', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::LoadConfig',
#         'filters' => [qw(Owner)]}
#     );
#     $self->create_node( 'SetConfig', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::SetConfig',
#         'filters' => [qw(Owner)]}
#     );
#     $self->create_node( 'Newsfilter', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::Newsfilter',
#         'filters' => [qw(Owner)]}
#     );
#     $self->create_node( 'ClearHistory', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::ClearHistory',
#         'filters' => [qw(Owner)]}
#     );
#     ## 1b. Group membership
#     $self->create_node( 'SelectGroup', '',
#       [qw(select_group EnsEMBL::Web::Component::Account::SelectGroup)],
#       { 'no_menu_entry' => 1 }
#     );
#     $self->create_node( 'ShareRecord', '',
#       [], { 'command' => 'EnsEMBL::Web::Command::ShareRecord',
#       'no_menu_entry' => 1 }
#     );
#     $self->create_node( 'Unsubscribe', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Unsubscribe',
#         'filters' => [qw(Member)]}
#     );
#     ## 2. Group admin
#     ## 2a. Group details
#     $self->create_node( 'ManageGroup', '',
#       [qw(manage_group EnsEMBL::Web::Component::Account::ManageGroup)],
#       { 'no_menu_entry' => 1 }
#     );
#     $self->create_node( 'Group', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::Group',
#         'filters' => [qw(Admin)]}
#     );
#     ## 2b. Group members
#     $self->create_node( 'Invite', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Invite',
#         'filters' => [qw(Admin)]}
#     );
#     $self->create_node( 'RemoveInvitation', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::RemoveInvitation',
#         'filters' => [qw(Admin)]}
#     );
#     $self->create_node( 'RemoveMember', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::RemoveMember',
#         'filters' => [qw(Admin)]}
#     );
#     $self->create_node( 'ChangeLevel', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::ChangeLevel',
#         'filters' => [qw(Admin)]}
#     );
#     $self->create_node( 'ChangeStatus', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::ChangeStatus',
#         'filters' => [qw(Admin)]}
#     );
#   }  
# }

sub populate_tree {
  my $self      = shift;
  my $hub       = $self->hub;
  my $user      = $hub->user;
  my $action    = $hub->action;
  my $function  = $hub->function;

  if ($user) {

    # main preferences page to view all settings with links to edit individual detail, group, bookmark etc
    my $preference_menu = $self->create_node('Preferences', 'Account Settings', [
      'notifications'     =>  'EnsEMBL::Users::Component::Account::Groups::Notifications',
      'view_details'      =>  'EnsEMBL::Users::Component::Account::Details::View',
      'view_groups'       =>  'EnsEMBL::Users::Component::Account::Groups::ViewAll',
      'view_bookmarks'    =>  'EnsEMBL::Users::Component::Account::Bookmark::View',
#       'view_newsfilter'   =>  'EnsEMBL::Users::Component::Account::Newsfilter::View'
    ], { 'availability'   =>  1 });

    # page to view user details
    my $details_menu = $preference_menu->append($self->create_node('Details', 'My Details', [
      'view_details'      =>  'EnsEMBL::Users::Component::Account::Details::View'
    ], { 'availability'   =>  1 }));

    # page to display a form to edit user details - name, email etc
    $details_menu->append($self->create_node('Details/Edit', 'Edit Details', [
      'edit_details'      =>  'EnsEMBL::Users::Component::Account::Details::Edit'
    ], { 'availability'   =>  1 }));

    # page to view groups user is a member of
    my $group_menu = $preference_menu->append($self->create_node('Groups', 'My Groups', [
      'message'           =>  'EnsEMBL::Users::Component::Account::Message',
      'notifications'     =>  'EnsEMBL::Users::Component::Account::Groups::Notifications',
      'view_groups'       =>  'EnsEMBL::Users::Component::Account::Groups::ViewAll'
    ], { 'availability'   =>  1 }));

    # page to view a single group
    $group_menu->append($self->create_node('Groups/View', 'View a group', [
      'message'           =>  'EnsEMBL::Users::Component::Account::Message',
      'view_group'        =>  'EnsEMBL::Users::Component::Account::Groups::View'
    ], { 'availability'   =>  1 }));

    # page to edit a group
    $group_menu->append($self->create_node('Groups/Edit', 'Edit a group', [
      'message'           =>  'EnsEMBL::Users::Component::Account::Message',
      'edit_group'        =>  'EnsEMBL::Users::Component::Account::Groups::AddEdit'
    ], { 'availability'   =>  1 }));

    # page to create a new group
    $group_menu->append($self->create_node('Groups/Add', 'Create new group', [
      'message'           =>  'EnsEMBL::Users::Component::Account::Message',
      'add_group'         =>  'EnsEMBL::Users::Component::Account::Groups::AddEdit'
    ], { 'availability'   =>  1 }));

    # page to list groups to be able to join an existing group
    $group_menu->append($self->create_node('Groups/List', 'Join existing group', [
      'message'           =>  'EnsEMBL::Users::Component::Account::Message',
      'list_groups'       =>  'EnsEMBL::Users::Component::Account::Groups::List'
    ], { 'availability'   =>  1 }));

    # page to create a new group
    $group_menu->append($self->create_node('Groups/Invite', 'Invite new members', [
      'message'           =>  'EnsEMBL::Users::Component::Account::Message',
      'add_group'         =>  'EnsEMBL::Users::Component::Account::Groups::Invite'
    ], { 'availability'   =>  1 }));


    # page to view user bookmarks
    my $bookmarks_menu = $preference_menu->append($self->create_node('Bookmark', 'My Bookmarks', [
      'view_bookmarks'    =>  'EnsEMBL::Users::Component::Account::Bookmark::View'
    ], { 'availability'   =>  1 }));

    # page to edit a bookmark
    $bookmarks_menu->append($self->create_node('Bookmark/Edit', 'Edit bookmark', [
      'edit_bookmark'     =>  'EnsEMBL::Users::Component::Account::Bookmark::AddEdit'
    ], { 'availability'   =>  1 }));

    # page to add a bookmark
    $bookmarks_menu->append($self->create_node('Bookmark/Add', 'Create new bookmark', [
      'add_bookmark'      =>  'EnsEMBL::Users::Component::Account::Bookmark::AddEdit'
    ], { 'availability'   =>  1 }));

    # page to share a bookmark with a group
    $bookmarks_menu->append($self->create_node('Share/Bookmark', 'Share bookmark', [
      'share_bookmark'    =>  'EnsEMBL::Users::Component::Account::Share::Bookmark'
    ], { 'availability'   =>  1 }));




#     # page to view user newsfilter
#     my $newsfilter_menu = $preference_menu->append($self->create_node('Newsfilter', 'My Newsfilter', [
#       'view_newsfilter'   =>  'EnsEMBL::Users::Component::Account::Newsfilter::View'
#     ], { 'availability'   =>  1 }));
# 
#     # page to edit a newsfilter
#     $newsfilter_menu->append($self->create_node('Newsfilter/Edit', 'Edit newsfilter', [
#       'edit_newsfilter'   =>  'EnsEMBL::Users::Component::Account::Newsfilter::AddEdit'
#     ], { 'no_menu_entry'  =>  1 }));
# 
#     # page to add a newsfilter
#     $newsfilter_menu->append($self->create_node('Newsfilter/Add', 'Create new newsfilter', [
#       'add_newsfilter'    =>  'EnsEMBL::Users::Component::Account::Newsfilter::AddEdit'
#     ], { 'availability'   =>  1 }));
























    # commands to save and reset favourites species
    $self->create_node("Favourites/$_",   '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Favourites::$_" }) for qw(Save Reset);

    # command to save the edited user details
    $self->create_node('Details/Save',    '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Details::Save'  });

    # command to save a bookmark
    $self->create_node('Bookmark/Save',   '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Bookmark::Save' });

    # command to removed any linked login account from the user accoubt
    $self->create_node('RemoveLogin',     '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::RemoveLogin'    });

    # commands to save, join, send invite for or delete a group
    $self->create_node("Group/$_",        '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Group::$_"      }) for qw(Save Join Invite Delete);

    # command to make changes to a membership object
    $self->create_node("Membership/$_",   '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Membership::$_" }) for (qw(Accept Decline BlockGroup Allow Ignore BlockUser Remove Unjoin Change));

  } else {

    # page to display login form and openid login options 
    $self->create_node('Login', 'Login', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'login'       =>  'EnsEMBL::Users::Component::Account::Login',
      'openid'      =>  'EnsEMBL::Users::Component::Account::OpenID::Buttons'
    ], { 'availability' => 1 });

    # page to display registration form and openid login options
    $self->create_node('Register', 'Register', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'register'    =>  'EnsEMBL::Users::Component::Account::Register',
      'openid'      =>  'EnsEMBL::Users::Component::Account::OpenID::Buttons'
    ], { 'availability' => 1 });

    # page displayed for lost password request
    $self->create_node('Password/Lost', 'Lost Password', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'password'    =>  'EnsEMBL::Users::Component::Account::Password::Lost'
    ], { 'availability' => 1 });

    # page displayed when user logs in to the site for the first time via openid to ask him some extra registration info
    $self->create_node('OpenIDRegister', '', [
      'message'     =>  'EnsEMBL::Users::Component::Account::Message',
      'register'    =>  'EnsEMBL::Users::Component::Account::OpenID::Register'
    ], { 'no_menu_entry' => 1  });

    $self->create_node( 'Confirmed',          '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::PasswordSave'     }); #intentionally kept same as Password/Save


    $self->create_node( 'User/Add',           '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::UserAdd'          });
    $self->create_node( 'Password/Retrieve',  '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::PasswordRetrieve' });
    $self->create_node( 'User/Authenticate',  '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::UserAuthenticate' });
    $self->create_node( 'OpenIDResponse',     '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::OpenID::Response' });
    $self->create_node( 'OpenIDRequest',      '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::OpenID::Request'  });
    $self->create_node( 'LinkAccount',        '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::LinkAccount'      });
    $self->create_node( 'Verify',             '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Details::Verify'  });
  }

  # page displayed for change password form
  $self->create_node('Password/Change', 'Change Password', [
    'message'     =>  'EnsEMBL::Users::Component::Account::Message',
    'password'    =>  'EnsEMBL::Users::Component::Account::Password::Change'
  ], { 'no_menu_entry' => 1 });

  $self->create_node( 'Password/Save',      '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::PasswordSave'     });

  # command to change the email after the user clicks on the verification email sent to his new address
  $self->create_node( 'Email/Change',       '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Details::ChangeEmail' });

  # page displayed with a form to choose a password when user clicks on the link in his email to verify his email
  $self->create_node('Confirm', '', [
    'message'       =>  'EnsEMBL::Users::Component::Account::Message',
    'confirmemail'  =>  'EnsEMBL::Users::Component::Account::Details::Confirm'
  ], { 'no_menu_entry' => 1  });



  $self->create_node( 'Message',        '', [qw(message EnsEMBL::Users::Component::Account::Message)],        { 'no_menu_entry' => 1 });

  $self->create_node( 'Logout', 'Logout', [], { 'command' => 'EnsEMBL::Users::Command::Account::Logout', 'availability' => 1, 'no_menu_entry' => !$user });

}

sub tree_cache_key {
  my ($self, $user, $session) = @_;
  
  ## Default trees for logged-in users and 
  ## for non logged-in are defferent
  ## but we cache both:
  my $class = ref $self;
  my $key = ($self->hub->user)
             ? "::${class}::TREE::USER"
             : "::${class}::TREE";

  ## If $user was passed this is for
  ## user_populate_tree (this user specific tree)
  $key .= '['. $user->id .']'
    if $user;

  return $key;
}

1;
