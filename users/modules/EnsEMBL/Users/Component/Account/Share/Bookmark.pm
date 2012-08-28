package EnsEMBL::Users::Component::Account::Share::Bookmark;

### Page for a logged in user to share his bookmarks with a group
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $user      = $hub->user->rose_object;
  my @subsections;

  # get all the active the groups with which bookmark can be shared
  my $memberships = $user->active_memberships;

  if (@$memberships) {

    # get all the bookmarks
    my $bookmarks = $user->bookmarks;

    if (@$bookmarks) {

      my $form = $self->select_group_form({
        'memberships' => $memberships,
        'action'      => $hub->url({qw(action Bookmark function Share)}),
        'name'        => 'group',
        'label'       => 'Group to share bookmark(s) with',
        'selected'    => $hub->param('group') || 0,
        'submit'      => 'Share',
      });

      $form->fieldset->prepend_child($self->select_bookmark_form({
        'bookmarks'   => $bookmarks,
        'label'       => 'Bookmark(s) to share',
        'multiple'    => 1,
        'selected'    => [ split ',', $hub->param('id') || '' ]
      })->fieldset->fields->[0]);

      # print a form if both groups and bookmarks found
      push @subsections, $form->render;

    } else {

      # if no bookmarks saved by the user
      push @subsections, '<p>You have not saved any bookmarks to your account.</p>', $self->link_add_bookmark;
    }

  } else {

    # if no group joined by the user
    push @subsections, '<p>You are not a member of any group to be able to share bookmarks to it.</p>', $self->link_create_new_group, $self->link_join_existing_group;
  }

  return $self->js_section({
    'id'          => 'share_bookmarks',
    'heading'     => 'Share bookmarks',
    'subsections' => \@subsections
  });
}

1;