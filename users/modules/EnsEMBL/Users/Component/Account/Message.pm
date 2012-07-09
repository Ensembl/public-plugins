package EnsEMBL::Users::Component::Account::Message;

### Component to display messages to user depending upon the keyword provided in get param
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self  = shift;
  my $hub   = $self->hub;

  my $err   = $hub->param('err');
  my $msg   = $hub->param('msg');

  return $self->render_message($err ? ($err, {'error' => 1}) : $msg) if $err || $msg;
}

1;