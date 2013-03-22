package EnsEMBL::Web::Configuration::Account;

use strict;

use base qw(EnsEMBL::Web::Configuration::UserData);

sub SECURE_PAGES {
  ## TODO
  ## @return List of url 'action' for all the pages that should be served over https
  return qw(Login);
}

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = $self->hub->user ? 'Preferences' : 'Login';
}

sub user_tree { return 1; }

sub user_populate_tree {}

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
