package EnsEMBL::Users::Component::Account::Bookmark::View;

### Page for a logged in user to view his bookmarks
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $user      = $hub->user->rose_object;
  my $bookmarks = $user->bookmarks;
  my %section   = (
    'id'          => 'view_bookmarks',
    'refresh_url' => {'action' => 'Bookmark', 'function' => ''}
  );

  return @$bookmarks
    ? $self->js_section({ %section, 'heading' => 'Bookmarks', 'subsections' => [ $self->bookmarks_table({'bookmarks' => $bookmarks}), $self->link_add_bookmark ] })
    : $self->no_bookmark_found_page(\%section)
  ;
}

1;