package EnsEMBL::Web::Hub;

use strict;

#use EnsEMBL::Web::Tools::MethodMaker (copy => {'new' => '__new', 'url' => '__url'}); ## TODO swap these two when 'new1' is renamed to 'new'
use EnsEMBL::Web::Tools::MethodMaker (copy => {'url' => '__url'});
use EnsEMBL::Web::User;
use EnsEMBL::Web::Configuration::Account;
use EnsEMBL::ORM::Rose::Object::User;

use constant CSRF_SAFE_PARAM => 'rxt';

sub PREFERENCES_PAGE { return shift->url({'type' => 'Account', 'action' => 'Preferences', 'function' => ''}); }

sub new1 { # TODO - change this to 'new' once user plugin is stable
  ## @overrides
  ## Overrides the constructor to initiate user object by reading the user cookie
  my ($class, $args) = @_;

  my $cookie  = delete $args->{'user_cookie'};
  my $self    = $class->__new($args);
  $self->user = EnsEMBL::Web::User->new($self, $cookie) if $cookie;
  return $self;
}

sub url {
  ## @overrides
  ## Clears the core params and species in case url type is Account
  ## Accepts the following extra keys as arguments
  ##  - csrf_safe : Required with value 1, if the url to be construted has to be safe from 'Cross site request forgery'
  ##  - user      : Required for CSRF safe urls only if the url is to be used by a user different to the logged in user (provide value undef if user yet to be created)
  my $self    = shift;
  my $extra   = $_[0] && !ref $_[0] ? shift : undef;
  my $params  = shift || {};
  my $url     = '';

  if (($params->{'type'} || '') eq 'Account' || $self->type eq 'Account') {
    $params->{'__clear'}    = 1;
    $params->{'species'}  ||= '';
  }

  if (delete $params->{'csrf_safe'}) {
    my $user = exists $params->{'user'} ? $params->{'user'} : $self->user;
    $params->{$self->CSRF_SAFE_PARAM} = $user ? $user->rose_object->salt : EnsEMBL::ORM::Rose::Object::User->DEFAULT_SALT;
  }

#  ($url = $self->species_defs->ENSEMBL_LOGIN_URL) =~ s/\/$// if grep { $params->{'action'} eq $_ } EnsEMBL::Web::Configuration::Account->SECURE_PAGES;

  return $url.$self->__url($extra || (), $params, @_);
}

sub get_favourite_species {
  my $self         = shift;
  my $user         = $self->user;
  my $species_defs = $self->species_defs;
  my @favourites   = $user ? @{$user->favourite_species} : ();
     @favourites   = @{$species_defs->DEFAULT_FAVOURITES || []} unless scalar @favourites;
     @favourites   = ($species_defs->ENSEMBL_PRIMARY_SPECIES, $species_defs->ENSEMBL_SECONDARY_SPECIES) unless scalar @favourites;
  return \@favourites;
}

sub initialize_user { # TODO remove this once user plugin is stable
  my ($self, $cookie) = @_;
  $self->user = EnsEMBL::Web::User->new($self, $cookie);
}

1;