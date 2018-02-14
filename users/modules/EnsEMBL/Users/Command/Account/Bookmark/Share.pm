=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Command::Account::Bookmark::Share;

### Command module to save a shared bookmark as a group record
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(
  MESSAGE_NO_GROUP_SELECTED
  MESSAGE_GROUP_NOT_FOUND
  MESSAGE_NO_BOOKMARK_SELECTED
  MESSAGE_BOOKMARK_NOT_FOUND
);

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self            = shift;
  my $object          = $self->object;
  my $hub             = $self->hub;
  my $user            = $hub->user;
  my $group_id        = $hub->param('group');
  my @bookmark_ids    = $hub->param('id');

  my $err;

  if (@bookmark_ids) {

    my $bookmarks = $user->records({'record_id' => \@bookmark_ids});

    if ($bookmarks->count) {

      if ($group_id) {

        my $group = $user->group($group_id);
        my $new_bookmarks;

        if ($group) {
          for (@$bookmarks) {
            my $bookmark_data = $_->clone_and_reset->data;
            $bookmark_data->{'click'} = 0;
            if (!$new_bookmarks) {
              $new_bookmarks = $group->add_record({'data' => $bookmark_data, 'type' => 'bookmark'});
            } else {
              $new_bookmarks->add($group->add_record({'data' => $bookmark_data, 'type' => 'bookmark'}));
            }
          }

          $new_bookmarks->save({'user' => $user});
          $user->has_changes(1);

          ## notify members if needed
          $self->send_group_sharing_notification_email($group, $new_bookmarks);
    
          return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id}));

        } else {
          $err = MESSAGE_GROUP_NOT_FOUND;
        }
      } else {
        $err = MESSAGE_NO_GROUP_SELECTED;
      }
    } else {
      $err = MESSAGE_BOOKMARK_NOT_FOUND;
    }
  } else {
    $err = MESSAGE_NO_BOOKMARK_SELECTED;
  }

  return $self->ajax_redirect($hub->url({'species' => '', 'type' => 'Account', 'action' => 'Share', 'function' => 'Bookmark', 'err' => $err}));
}

1;
