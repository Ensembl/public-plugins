package EnsEMBL::Users::Command::Account::Bookmark::Use;

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_BOOKMARK_NOT_FOUND);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $bookmark_id = $hub->param('id');

  if (my ($bookmark, $owner) = $object->fetch_bookmark_with_owner( $bookmark_id ? ($bookmark_id, $hub->param('group')) : 0 )) {
    $bookmark->click(($bookmark->click || 0) + 1);
    $bookmark->save('user' => $hub->user);
    my $url = $bookmark->url;
    return $hub->redirect($url =~ /^(ht|f)tp/ ? $url : "http://$url");

  } else {
    return $self->redirect_message(MESSAGE_BOOKMARK_NOT_FOUND);
  }
}

1;