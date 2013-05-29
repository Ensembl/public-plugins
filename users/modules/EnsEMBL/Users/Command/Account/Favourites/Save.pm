package EnsEMBL::Users::Command::Account::Favourites::Save;

use strict;

use base qw(EnsEMBL::Users::Command::Account);

use EnsEMBL::Web::Document::HTML::FavouriteSpecies;

sub process {
  my $self    = shift;
  my $hub     = $self->hub;
  my $r_user  = $hub->user->rose_object;

  my ($species_list)  = @{$r_user->specieslists};
      $species_list ||= $r_user->create_record('specieslist');

  $species_list->favourites($hub->param('favourites'));
  $species_list->save('user' => $r_user);

  print EnsEMBL::Web::Document::HTML::FavouriteSpecies->new($hub)->render('fragment');

}

1;
