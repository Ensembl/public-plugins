=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Hub;

use strict;
use warnings;

use previous qw(new url get_favourite_species store_records_if_needed);

use EnsEMBL::Web::User;
use EnsEMBL::Web::Exceptions;

sub CSRF_SAFE_PARAM   { 'rxt'; }
sub PREFERENCES_PAGE  { $_[0]->url({'type' => 'Account', 'action' => 'Preferences', 'function' => ''}); }

sub new {
  ## @overrides
  my $self = shift->PREV::new(@_);

  $self->init_user;

  return $self;
}

sub init_user {
  ## Initialises User object
  my $self = shift;

  $self->{'_user'} = EnsEMBL::Web::User->new($self);
}

sub url {
  ## @overrides
  ## Clears the core params in case url type is Account
  ## Accepts the following extra keys as arguments
  ##  - csrf_safe : Required with value 1, if the url to be construted has to be safe from 'Cross site request forgery'
  ##  - user      : Required for CSRF safe urls only if the url is to be used by a user different to the logged in user (provide value undef if user yet to be created)
  my $self      = shift;
  my $extra     = $_[0] && !ref $_[0] ? shift : undef;
  my $params    = shift || {};
  my $base_url  = '';

  if (($params->{'type'} || $self->type || '') eq 'Account') {
    $params->{'__clear'} = 1;
    $params->{'species'} = 'Multi' if !$params->{'species'} || $params->{'species'} eq 'common';
  }

  if (delete $params->{'csrf_safe'}) {
    my $user = exists $params->{'user'} ? $params->{'user'} : $self->user;
    $params->{$self->CSRF_SAFE_PARAM} = $user ? $user->rose_object->salt : EnsEMBL::Web::User->default_salt;
  }

  # https url
  # $params->{'action'} eq $_ and ($base_url = $self->species_defs->ENSEMBL_LOGIN_URL) =~ s/\/$// and last for EnsEMBL::Web::Configuration::Account->SECURE_PAGES;

  my $url = $self->PREV::url($extra || (), $params, @_);

  return $base_url ? "$base_url$url" : $url;
}

sub get_favourite_species {
  my $self        = shift;
  my $user        = $self->user;
  my @favourites  = $user ? @{$user->favourite_species} : ();

  return @favourites ? \@favourites : $self->PREV::get_favourite_species;
}

sub users_plugin_available {
  ## Checks if the user plugin is available
  return 1;
}

sub users_available {
  ## Gets/Sets the flag to check whether users db is connected or not
  ## @param Flag value if setting
  ## @return 0 or 1 accordingly
  my $self = shift;

  $self->{'_users_available'} = shift if @_;

  unless (exists $self->{'_users_available'}) {
    $self->{'_users_available'} = 1;
    try {
      EnsEMBL::Web::User->user_rose_manager->object_class->init_db->connect;
    } catch {
      $self->log_userdb_error($_);
      $self->{'_users_available'} = 0;
    }
  }

  return $self->{'_users_available'};
}

sub log_userdb_error {
  ## Logs the error thrown by userdb in case the connection could not be created
  ## @param Exception object
  my ($self, $exception) = @_;
  warn $exception->message(1);
}

sub store_records_if_needed {
  my $self  = shift;
  my $user  = $self->user;

  $user->store_records if $user;

  $self->PREV::store_records_if_needed;
}

1;
