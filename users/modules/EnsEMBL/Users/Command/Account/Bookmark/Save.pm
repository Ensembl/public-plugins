package EnsEMBL::Users::Command::Account::Bookmark::Save;

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_BOOKMARK_NOT_FOUND);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $bookmark_id = $hub->param('id');

  if (my ($bookmark, $owner) = $object->fetch_bookmark_with_owner( $bookmark_id ? ($bookmark_id, $hub->param('group')) : 0 )) {
    $bookmark->$_($hub->param($_)) for qw(name shortname url object);
    $bookmark->save('user' => $hub->user);

    return $self->ajax_redirect($hub->url($owner->RECORD_TYPE eq 'group'
      ? {'action' => 'Groups',    'function' => 'View', 'id' => $owner->group_id}
      : {'action' => 'Bookmark',  'function' => ''}
    ));

  } else {
    return $self->redirect_message(MESSAGE_BOOKMARK_NOT_FOUND, {'error' => 1});
  }
}

1;
