package EnsEMBL::Web::Hub;

use strict;

#use EnsEMBL::Web::Tools::MethodMaker (copy => {'new' => '__new', 'url' => '__url'}); ## TODO swap these two when 'new1' is renamed to 'new'
use EnsEMBL::Web::Tools::MethodMaker (copy => {'url' => '__url'});
use EnsEMBL::Web::User;

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
  my $self    = shift;
  my $params  = shift;

  if (ref $params && (($params->{'type'} || '') eq 'Account' || $self->type eq 'Account')) { # ignore this if second argument is the 'extra' argument
    $params->{'__clear'}    = 1;
    $params->{'species'}  ||= '';
  }

  return $self->__url($params, @_);
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

sub initialize_user { # TODO removed this once user plugin is stable
  my ($self, $cookie) = @_;
  $self->user = EnsEMBL::Web::User->new($self, $cookie);
}

1;