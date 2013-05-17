package EnsEMBL::Users::Command::Account::Bookmark::Remove;

### Command module to remvoe a bookmark record (user bookmark or group bookmark)
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_CANT_DELETE_BOOKMARK MESSAGE_BOOKMARK_NOT_FOUND);

use base qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $bookmark_id = $hub->param('id');

  if (my ($bookmark, $owner) = $object->fetch_bookmark_with_owner( $bookmark_id ? ($bookmark_id, $hub->param('group')) : 0 )) {

    my $redirect_url = {'action' => 'Bookmark', 'function' => 'View'};

    if ($owner->RECORD_TYPE eq 'group') {
      if ($bookmark->created_by eq $user->user_id || $user->is_admin_of($owner)) {
        $redirect_url = {'action' => 'Groups', 'function' => 'View', 'id' => $owner->group_id};
      } else {
        return $self->redirect_message(MESSAGE_CANT_DELETE_BOOKMARK, {'error' => 1});
      }
    }

    $bookmark->delete;

    return $self->ajax_redirect($hub->url($redirect_url));

  } else {
    return $self->redirect_message(MESSAGE_BOOKMARK_NOT_FOUND, {'error' => 1});
  }
}

1;
