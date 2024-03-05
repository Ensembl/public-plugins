=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Component::Account::Share::Bookmark;

### Page for a logged in user to share his bookmarks with a group
### @author hr5

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $user      = $hub->user;
  my @subsections;

  # get all the bookmarks
  my $bookmarks = $user->bookmarks;

  if (@$bookmarks) {

    # get all the active the groups with which bookmark can be shared
    my $memberships = $user->active_memberships;

    if (@$memberships) {

      my $form = $self->select_group_form({
        'memberships' => $memberships,
        'action'      => {qw(action Bookmark function Share)},
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

      # if no group joined by the user
      push @subsections, sprintf '<p>You are not a member of any group to be able to share bookmarks to it. You can <a href="%s">join an existing group</a> or <a href="%s">create a new group</a> to share your bookmarks with others %s users.</p>',
        $hub->url({'action' => 'Groups', 'function' => 'List'}),
        $hub->url({'action' => 'Groups', 'function' => 'Add' }),
        $self->site_name
      ;
    }

  } else {

    # if no bookmarks saved by the user
    push @subsections, $self->no_bookmark_message(1);
  }

  return $self->js_section({
    'heading'     => 'Share bookmark',
    'subsections' => \@subsections
  });
}

1;