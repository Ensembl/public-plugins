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

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self            = shift;
  my $object          = $self->object;
  my $hub             = $self->hub;
  my $r_user          = $hub->user->rose_object;
  my $group_id        = $hub->param('group');
  my @bookmark_ids    = $hub->param('id');

  my $err;

  if (@bookmark_ids) {

    my $bookmarks = $r_user->find_bookmarks(['record_id' => \@bookmark_ids]);

    if ($bookmarks && @$bookmarks) {

      if ($group_id) {

        my $membership    = $object->fetch_active_membership_for_user($r_user, $group_id);
        my $group         = $membership ? $membership->group : undef;
        my $new_bookmarks = [];
    
        if ($group) {
          for (@$bookmarks) {
            my $bookmark = $_->clone_and_reset;
            $bookmark->record_type($group->RECORD_TYPE);
            $bookmark->record_type_id($group->group_id);
            $bookmark->click(0);
            $bookmark->save(user => $r_user);
            push @$new_bookmarks, $bookmark;
          }
    
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
