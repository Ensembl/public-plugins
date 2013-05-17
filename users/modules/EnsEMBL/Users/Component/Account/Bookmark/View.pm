package EnsEMBL::Users::Component::Account::Bookmark::View;

### Page for a logged in user to view his bookmarks
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $r_user          = $hub->user->rose_object;
  my $bookmarks       = $r_user->bookmarks;
  my $memberships     = $r_user->active_memberships;
  my $group_bookmarks = [ map { @{$_->group ? $_->group->bookmarks : ()} } @$memberships ];

  return join '',
    $self->js_section({
      'heading'           => 'My bookmarks',
      'heading_links'     => [{
        'href'              => {qw(action Bookmark function Add)},
        'title'             => 'Add a bookmark',
        'sprite'            => 'bookmark_icon'
      }],
      'subsections'       => [ @$bookmarks ? $self->bookmarks_table({'bookmarks' => $bookmarks}) : $self->no_bookmark_message ]
    }), @$group_bookmarks ?
    $self->js_section({
      'heading'           => 'Shared bookmarks',
      'subsections'       => [ $self->bookmarks_table({'bookmarks' => $group_bookmarks, 'shared' => 1}) ]
    }) : ()
  ;
}

1;