package EnsEMBL::Users::Component::Account::Down;

### Component to display messages to user if userdb is down
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self = shift;

  return sprintf
    '<div class="info">
      <h3>User accounts not available</h3>
      <div class="message-pad"><p>%s user accounts feature is temporarily not available due to unavailability of users database.</p></div>
    </div>', $self->hub->species_defs->ENSEMBL_SITETYPE
  ;
}

1;