package EnsEMBL::Users::Command::Account::Bookmark::Save;

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_BOOKMARK_NOT_FOUND);

use base qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $bookmark_id = $hub->param('id');

  if (my ($bookmark, $record_owner) = $object->fetch_bookmark_with_owner( $bookmark_id ? ($bookmark_id, $hub->param('group')) : 0 )) {

    # if we need to save a new copy of the bookmark
    if ($record_owner->RECORD_TYPE eq 'group' && ($hub->param('save_new') || !($user->is_admin_of($record_owner) || $bookmark->created_by eq $user->user_id))) {
      $bookmark = $bookmark->clone_and_reset;
      $bookmark->click(0);
    }

    $bookmark->$_($hub->param($_)) for qw(name description url object);
    $bookmark->save('user' => $user);

    return $self->ajax_redirect($hub->url($record_owner->RECORD_TYPE eq 'group'
      ? {'action' => 'Groups',    'function' => 'View', 'id' => $record_owner->group_id}
      : {'action' => 'Bookmark',  'function' => ''}
    ));

  } else {
    return $self->redirect_message(MESSAGE_BOOKMARK_NOT_FOUND, {'error' => 1});
  }
}

1;
