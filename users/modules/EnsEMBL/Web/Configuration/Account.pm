=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use base qw(EnsEMBL::Web::Configuration::UserData);

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

1;
