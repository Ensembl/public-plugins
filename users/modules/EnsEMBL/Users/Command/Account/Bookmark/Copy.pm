package EnsEMBL::Users::Command::Account::Bookmark::Copy;

### Command module to copy a group bookmark to user bookmarks
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_UNKNOWN_ERROR);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $r_user      = $hub->user->rose_object;
  my $bookmark_id = $hub->param('id');
  my $group_id    = $hub->param('group');

  if ($bookmark_id && $group_id) {

    if (my ($bookmark, $owner) = $object->fetch_bookmark_with_owner($bookmark_id, $group_id)) {
      $bookmark = $bookmark->clone_and_reset;
      $bookmark->record_type($r_user->RECORD_TYPE);
      $bookmark->record_type_id($r_user->user_id);
      $bookmark->click(0);
      $bookmark->save('user' => $r_user);
      return $self->ajax_redirect($hub->url({'action' => 'Bookmark', 'function' => ''}));
    }
  }
  return $self->redirect_message(MESSAGE_UNKNOWN_ERROR, {'error' => 1});
}

1;
