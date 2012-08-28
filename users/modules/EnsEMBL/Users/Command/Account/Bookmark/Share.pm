package EnsEMBL::Users::Command::Account::Bookmark::Share;

### Command module to save a shared bookmark as a group record
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self          = shift;
  my $object        = $self->object;
  my $hub           = $self->hub;
  my $r_user        = $hub->user->rose_object;
  my $group_id      = $hub->param('group');
  my @bookmark_ids  = $hub->param('id');

  if (@bookmark_ids && $group_id) {

    my $bookmarks   = $r_user->find_bookmarks(['record_id' => \@bookmark_ids]);
    my $membership  = $object->fetch_active_membership_for_user($r_user, $group_id);
    my $group       = $membership ? $membership->group : undef;

    if (@$bookmarks && $group) {
      for (@$bookmarks) {
        my $bookmark = $_->clone_and_reset;
        $bookmark->owner_type($group->RECORD_OWNER_TYPE);
        $bookmark->owner_id($group->group_id);
        $bookmark->click(0);
        $bookmark->save(user => $r_user);
      }
      return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id}));
    }
  }

  return $self->redirect_message('MESSAGE_UNKNOWN_ERROR', {'error' => 1});
}

1;
