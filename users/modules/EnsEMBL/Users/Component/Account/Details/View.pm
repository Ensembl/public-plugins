package EnsEMBL::Users::Component::Account::Details::View;

### Page for a logged in user to view his detals
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self              = shift;
  my $hub               = $self->hub;
  my $object            = $self->object;
  my $web_user          = $hub->user;
  my $rose_user         = $web_user->rose_object;

  return $self->js_section({
    'id'            => 'view_details',
    'refresh_url'   => {'action' => 'Details', 'function' => ''},
    'heading'       => 'User Details',
    'subsections'   => [
      $self->two_column([
        'Name'          => $web_user->display_name,
        'Email'         => $web_user->display_email,
        'Organisation'  => $web_user->display_organisation,
        'Country'       => $web_user->display_country,
        'Login via'     => join('<br />', map {
          my $login_type = $_->type;
          $login_type ne 'openid' ? $login_type ne 'local'
          ? sprintf('%s (LDAP)', $_->ldap_user)
          : sprintf('%s (%s)', $_->identity, $self->js_link({'href' => {qw(action Password function Change)}, 'caption' => 'Change password', 'inline' => 1}))
          : sprintf(@{$rose_user->logins} > 1 ? '%s%s (%s)' : '%s (%s)', $_->provider, $_->has_trusted_provider ? $_->email : $_->identity, $self->js_link({'href' => {'action' => 'RemoveLogin', 'id' => $_->login_id}, 'caption' => 'Remove login', 'inline' => 1}))
        } @{$rose_user->logins})
      ]),
      $self->js_link({
        'class'   => 'setting',
        'href'    => {qw(action Details function Edit)},
        'caption' => 'Edit'
      })
    ]
  });
}

1;