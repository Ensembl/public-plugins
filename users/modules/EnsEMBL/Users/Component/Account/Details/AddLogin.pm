package EnsEMBL::Users::Component::Account::Details::AddLogin;

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account::OpenID::Buttons);

use EnsEMBL::Users::Messages qw(MESSAGE_NO_LOGIN_AVAILABLE);

sub content {
  ## @overrides
  my $self              = shift;
  my $openid_providers  = $self->object->openid_providers;
  my %existing_logins   = map {$_->provider => 1} @{$self->hub->user->rose_object->find_logins('query' => ['type' => 'openid'])};

  my $available_openid_providers = [];
  while (my ($provider, $details) = splice @$openid_providers, 0, 2) {
    push @$available_openid_providers, $provider, $details unless exists $existing_logins{$provider};
  }

  return @$available_openid_providers
    ? $self->SUPER::buttons($available_openid_providers)->render
    : $self->render_message(MESSAGE_NO_LOGIN_AVAILABLE)
  ;
}

1;