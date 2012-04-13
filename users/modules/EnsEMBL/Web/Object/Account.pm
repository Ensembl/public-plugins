package EnsEMBL::Web::Object::Account;

### NAME: EnsEMBL::Web::Object::Account
### Object for accessing user account information 

### DESCRIPTION
### This module does not wrap around a data object, it merely
### accesses the user object via the session

use strict;

use Net::OpenID::Consumer;
use LWP::UserAgent;

use EnsEMBL::Web::Cookie;
use EnsEMBL::ORM::Rose::Manager::User;
use EnsEMBL::ORM::Rose::Manager::Login;

use base qw(EnsEMBL::Web::Object);

sub new {
  ## @overrides
  my $self = shift->SUPER::new(@_);
  $self->can($_) and $self->$_ for lc sprintf('fetch_for_%s', $self->action || $self->default_action);
  return $self;
}

sub caption               { return 'Your Account';                            }
sub short_caption         { return 'Account Management';                      }
sub default_action        { return $_[0]->hub->user ? 'Preferences' : 'Login' }

sub fetch_for_register    {}
sub fetch_for_preferences {}
sub fetch_for_setcookie   {}
sub fetch_for_linkaccount { return shift->fetch_for_selectaccount;                                      }

sub get_root_url          { return $_[0]->{'_root_url'} ||= $_[0]->hub->species_defs->ENSEMBL_BASE_URL; }
sub get_user_by_id        { return EnsEMBL::ORM::Rose::Manager::User->get_by_id($_[1]);                 }
sub get_user_by_email     { return EnsEMBL::ORM::Rose::Manager::User->get_by_email($_[1]);              }
sub get_login_account     { return EnsEMBL::ORM::Rose::Manager::Login->get_by_identity($_[1]);          }
sub new_login_account     { return EnsEMBL::ORM::Rose::Manager::Login->create_empty_object($_[1]);      }

sub get_url_code_for_login {
  ## Creates a url code for a given login and user
  ## @param Login object
  ## @param User object (default to user linked to login object)
  ## @return String
  my ($self, $login, $user) = @_;
  $user ||= $login->user;

  return sprintf('%s-%s-%s', $user ? $user->user_id : '0', $login->login_id, $login->salt);
}

sub get_login_from_url_code {
  ## Fetches and returns a login object by parsing the code parameter in the url
  ## @return Login object for matching salt, login id and user id, undef otherwise
  my ($self, $ignore_user) = @_;

  $self->hub->param('code') =~ /^([0-9]+)\-([0-9]+)\-([a-zA-Z0-9_]+)$/;

  my $login = EnsEMBL::ORM::Rose::Manager::Login->get_objects(
    'with_objects'  => [ 'user' ],
    'query'         => [ 'login_id', $2, 'salt', $3 ],
    'limit'         => 1
  )->[0];

  if ($login) {
    return $login if $ignore_user;
    my $user = $login->user;
    return $login if $user && $user->user_id eq $1 && $user->status eq 'active';
  }

  return undef;
}

sub new_user_account {
  ## @return unsaved EnsEMBL::ORM::Rose::Object::User object
  my ($self, $params) = @_;

  return EnsEMBL::ORM::Rose::Manager::User->create_empty_object({
    'status'  => 'active',
    'email'   => delete $params->{'email'},
    'name'    => delete $params->{'name'} || sprintf('%s User', $self->hub->species_defs->ENSEMBL_SITETYPE),
    %$params
  });
}

sub fetch_for_selectaccount {
  my $self = shift;

  $self->rose_objects($self->get_login_from_url_code(1));
}

sub openid_providers {
  return [ map {$_} @{shift->hub->species_defs->OPENID_PROVIDERS} ];
}

sub get_openid_consumer {
  ## Gets the openid consumer object used to openid login process
  ## @return Net::OpenID::Consumer
  my $self    = shift;
  my $hub     = $self->hub;
  my $ua      = LWP::UserAgent->new;

  $ua->proxy([qw(http https)], $_) for $hub->species_defs->ENSEMBL_WWW_PROXY || ();

  return Net::OpenID::Consumer->new(
    'ua'              => $ua,
    'required_root'   => $self->get_root_url,
    'args'            => $hub->input,
    'consumer_secret' => 'ifyhvlksej14', # TODO
  );
}

sub get_openid_url {
  my ($self, $provider, $username) = @_;

  my $openid_providers = $self->openid_providers;

  while (my ($key, $value) = splice @$openid_providers, 0, 2) {
    if ($key eq $provider) {
      $value->{'url'} =~ s/\[USERNAME\]/$username/;
      return $value->{'url'};
    }
  }
}

sub user_cookie {
  ## Gets the cookie saved against ENSEMBL_USER_ID
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

sub activate_user {
  ## Activates the user by reading 'code' GET parameter
  ## @return Boolean true if activated successfully, false otherwise
  my $self  = shift;
  my $login = $self->get_login_from_url_code or return 0;

  $login->activate;
  return $login->save;
}

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
