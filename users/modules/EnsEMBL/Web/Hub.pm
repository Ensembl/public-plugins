package EnsEMBL::Web::Hub;

use strict;

use EnsEMBL::Web::Tools::MethodMaker (copy => {'new' => '__new', 'url' => '__url'});
use EnsEMBL::Web::User;

sub new {
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
  if (!$params->{'type'} && $self->referer->{'ENSEMBL_TYPE'} eq 'Account' || $params->{'type'} eq 'Account') {
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

1;