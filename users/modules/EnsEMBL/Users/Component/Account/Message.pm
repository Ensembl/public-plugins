package EnsEMBL::Users::Component::Account::Message;

### Component to display messages to user depending upon the keyword provided in get param
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self  = shift;
  my $hub   = $self->hub;

  return $self->render_message($hub->param('err') ? ($hub->param('err'), {'error' => 1}) : ($hub->param('msg'), {'error' => 0}));
}

1;