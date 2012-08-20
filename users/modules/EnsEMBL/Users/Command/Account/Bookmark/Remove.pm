package EnsEMBL::Users::Command::Account::Bookmark::Remove;

use strict;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $bookmark_id = $hub->param('id');

  if (my ($bookmark, $owner) = $object->fetch_bookmark_with_owner( $bookmark_id ? ($bookmark_id, $hub->param('group')) : 0 )) {

    my $redirect_url = {'action' => 'Bookmark', 'function' => 'View'};

    if ($owner->RECORD_OWNER_TYPE eq 'group') {
      if ($bookmark->created_by eq $user || $user->is_admin_of($owner)) {
        $redirect_url = {'action' => 'Groups', 'function' => 'View', 'id' => $owner->group_id};
      } else {
        return $self->redirect_message('MESSAGE_CANT_DELETE_BOOKMARK', {'error' => 1});
      }
    }

    $bookmark->delete;

    return $self->ajax_redirect($hub->url($redirect_url));

  } else {
    return $self->redirect_message('MESSAGE_BOOKMARK_NOT_FOUND', {'error' => 1});
  }
}

1;
