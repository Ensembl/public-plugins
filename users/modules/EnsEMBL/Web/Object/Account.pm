package EnsEMBL::Web::Object::Account;

### NAME: EnsEMBL::Web::Object::Account
### Object for accessing user account information 

### DESCRIPTION
### This module does not wrap around a data object, it merely
### accesses the user object via the session

use strict;

use EnsEMBL::Web::Cookie;

use base qw(EnsEMBL::Web::Object::DbFrontend);

sub caption           { return 'Your Account';        }
sub short_caption     { return 'Account Management';  }

sub manager_class     { return shift->rose_manager('User');           }
sub default_action    { return $_[0]->hub->user ? 'Preferences' : 'Login' }

sub show_trackable_fields { return 'never'; }
sub show_preview          { return 0;       }

sub fetch_for_login     {}
sub fetch_for_logout    {}
sub fetch_for_register  { shift->fetch_for_add; }












sub user_cookie {
  my $species_defs = shift->hub->species_defs;
  return EnsEMBL::Web::Cookie->new({
    'host'    => $species_defs->ENSEMBL_COOKIEHOST,
    'name'    => $species_defs->ENSEMBL_USER_COOKIE,
    'value'   => '',
    'env'     => 'ENSEMBL_USER_ID',
    'hash'    => {
      'offset'  => $species_defs->ENSEMBL_ENCRYPT_0,
      'key1'    => $species_defs->ENSEMBL_ENCRYPT_1,
      'key2'    => $species_defs->ENSEMBL_ENCRYPT_2,
      'key3'    => $species_defs->ENSEMBL_ENCRYPT_3,
      'expiry'  => $species_defs->ENSEMBL_ENCRYPT_EXPIRY,
      'refresh' => $species_defs->ENSEMBL_ENCRYPT_REFRESH
    }
  });
}


## fetch_for_page methods ##;
sub fetch_for_preferences   {
  my $self = shift;
#   my $user = $self->hub->user;
#   $user->reload;
#   $self->rose_objects($user->rose_object);

  # TODO - temporary stuff ... remove it and uncomment the code above after hub->user is formed correctly
  my $user = $self->manager_class->get_by_id($self->hub->user->user_id);
  $self->rose_objects($user);
}

sub fetch_for_setcookie {
  my $self  = shift;
  $self->rose_objects($self->manager_class->get_by_email($self->hub->param('email')));
}

sub show_fields {
  return [
    'name'          => {
      'label'     => 'Your name',
      'type'      => 'String',
      'required'  => 1
    },
    'email'         => {
      'label'     => 'Your email address',
      'type'      => 'Email',
      'required'  => 1
    },
    'organisation'  => {
      'label'     => 'Organisation',
      'type'      => 'String'
    }
  ];
}

sub fetch_for_links {}


sub counts {
  my $self         = shift;
  my $hub          = $self->hub;
  my $user         = $hub->user;
  my $session      = $hub->session;
  my $species_defs = $hub->species_defs;
  my $counts       = {};

  if ($user && $user->id) {
    $counts->{'bookmarks'}      = $user->bookmarks->count;
    $counts->{'configurations'} = $user->configurations->count;
    $counts->{'annotations'}    = $user->annotations->count;
    
    # EnsembleGenomes sites share session and user account - only count data that is attached to species in current site
    $counts->{'userdata'} = 0;
    my @userdata = (
      $session->get_data('type' => 'upload'),
      $session->get_data('type' => 'url'), 
      $session->get_all_das,
      $user->uploads,
      $user->dases, 
      $user->urls
    );
    foreach my $item (@userdata) {
      next unless $item and $species_defs->valid_species(ref ($item) =~ /Record/ ? $item->species : $item->{species});
      $counts->{'userdata'} ++;
    }
    
    my @groups  = $user->find_nonadmin_groups;
    foreach my $group (@groups) {
      $counts->{'bookmarks'}      += $group->bookmarks->count;
      $counts->{'configurations'} += $group->configurations->count;
      $counts->{'annotations'}    += $group->annotations->count;
    }

    $counts->{'news_filters'} = $user->newsfilters->count;
    $counts->{'admin'}        = $user->find_administratable_groups;
    $counts->{'member'}       = scalar(@groups);
  }

  return $counts;
}

1;
