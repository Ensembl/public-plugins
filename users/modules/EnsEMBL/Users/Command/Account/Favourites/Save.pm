package EnsEMBL::Users::Command::Account::Favourites::Save;

use strict;

use base qw(EnsEMBL::Users::Command::Account);

use EnsEMBL::Web::Document::HTML::FavouriteSpecies;

sub process {
  my $self = shift;
  my $hub  = $self->hub;
  my $user = $hub->user;

  my ($species_list)  = @{$user->specieslists};
      $species_list ||= $user->create_record('specieslist');

  $species_list->favourites($hub->param('favourites'));
  $species_list->save('user' => $user);

  print EnsEMBL::Web::Document::HTML::FavouriteSpecies->new($hub)->render('fragment');

}

1;
