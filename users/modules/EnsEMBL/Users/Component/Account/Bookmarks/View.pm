package EnsEMBL::Users::Component::Account::Bookmarks::View;

### Page for a logged in user to view his bookmarks
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self              = shift;
  my $hub               = $self->hub;
  my $object            = $self->object;
  my $user              = $hub->user->rose_object;
  my $bookmarks         = $user->bookmarks;

  return $self->js_section({
    'id'          => 'view_bookmarks',
    'heading'     => 'Bookmarks',
    'refresh_url' => {'action' => 'Bookmarks', 'function' => ''},
    'subsections' => [ @$bookmarks
      ? $self->bookmarks_table({'bookmarks' => $bookmarks})
      : q(<p>You have no saved bookmark</p>),
      $self->link_add_bookmark
    ]
  });
}

1;