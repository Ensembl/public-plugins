package EnsEMBL::Web::Object::Account;

### Plugin file for Account object in the users plugin

use strict;

sub login_has_trusted_provider {
  ## In case of an openid login, tells whether the provider is trusted or not.
  ## @return 1 if trusted openid provider, 0 if not trusted or if login is not of type openid
  my ($self, $login) = @_;

  return $login->type eq 'openid' ? {@{$self->hub->species_defs->OPENID_PROVIDERS}}->{$login->provider}->{'trusted'} : 0;
}
