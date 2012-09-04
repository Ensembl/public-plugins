package EnsEMBL::Users::Component::Account::Details::View;

### Page for a logged in user to view his detals
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $object        = $self->object;
  my $user          = $hub->user;
  my $r_user        = $user->rose_object;
  my $logins        = $r_user->logins;
  my $site_name     = $self->site_name;
  
  my @login_details;

  for (@$logins) {
    my $login_type      = $_->type;
    my $login_provider  = $_->provider;
    my $login_detail    = '<b>%s</b>: %s ';

    if ($login_type eq 'local') {
      $login_detail = sprintf "$login_detail %s ", $site_name, $_->identity, $self->js_link({
        'class'   => 'small',
        'href'    => {qw(action Password function Change)},
        'caption' => 'Change password',
        'inline'  => 1
      });

    } elsif ($login_type eq 'openid') {
      $login_detail = sprintf $login_detail, $login_provider, $_->has_trusted_provider ? $_->email : $_->identity;

    } elsif ($login_type eq 'ldap') { # not implimented yet
      $login_detail = sprintf $login_detail, 'LDAP', $_->ldap_user;
    }

    # add a remove login link for local or openid logins
    if (@$logins > 1 && $login_type =~ /^(local|openid)$/) {
      $login_detail .= $self->js_link({
        'class'   => 'small',
        'href'    => {'action' => 'Details', 'function' => 'RemoveLogin', 'id' => $_->login_id},
        'caption' => 'Remove login',
        'inline'  => 1,
        'confirm' => sprintf(q(You won't be able to login to %s site with your %s account.), $site_name, $login_type eq 'local' ? $site_name : $login_provider)
      });
    }

    push @login_details, $login_detail;
  }

  return $self->js_section({
    'id'            => 'view_details',
    'refresh_url'   => {'action' => 'Details', 'function' => ''},
    'heading'       => 'User Details',
    'subsections'   => [
      $self->two_column([
        'Name'          => $user->display_name,
        'Email'         => $user->display_email,
        'Organisation'  => $user->display_organisation,
        'Country'       => $user->display_country,
        'Login via'     => @login_details > 1 ? sprintf('<div class="spaced">%s</div>', join('<br />', @login_details)) : $login_details[0]
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