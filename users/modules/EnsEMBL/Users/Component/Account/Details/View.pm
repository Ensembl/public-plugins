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
  
  my (@existing_openid_logins, @login_details);

  for (@$logins) {
    my $login_type      = $_->type;
    my $login_provider  = $_->provider;
    my $login_detail    = '<b>%s</b>: %s ';

    if ($login_type eq 'local') {
      $login_detail = sprintf "$login_detail %s ", $site_name, $_->identity, $self->js_link({
        'class'   => 'small',
        'href'    => {qw(action Password function Change)},
        'caption' => 'Change password'
      });

    } elsif ($login_type eq 'openid') {
      $login_detail = sprintf $login_detail, $login_provider, $_->has_trusted_provider ? $_->email : $_->identity;
      push @existing_openid_logins, $login_provider;

    } elsif ($login_type eq 'ldap') { # not implimented yet
      $login_detail = sprintf $login_detail, 'LDAP', $_->ldap_user;
    }

    # add a remove login link for local or openid logins
    if (@$logins > 1 && $login_type =~ /^(local|openid)$/) {
      $login_detail .= $self->js_link({
        'class'   => 'small',
        'href'    => {'action' => 'Details', 'function' => 'RemoveLogin', 'id' => $_->login_id},
        'caption' => 'Remove login',
        'confirm' => sprintf(q(You won't be able to login to %s site with your %s account.), $site_name, $login_type eq 'local' ? $site_name : $login_provider)
      });
    }

    push @login_details, $login_detail;
  }

  push @login_details, $self->js_link({
    'caption' => 'Add login',
    'helptip' => sprintf('Click to add another login option via %s', $self->join_with_or(grep {!ref $_} @{$self->object->openid_providers})),
    'href'    => {qw(action Details function AddLogin)}
  });

  return $self->js_section({
    'id'            => 'view_details',
    'refresh_url'   => {'action' => 'Details', 'function' => ''},
    'heading'       => 'User Details',
    'heading_links' => [{
      'sprite'        => 'edit_icon',
      'href'          => {qw(action Details function Edit)},
      'title'         => 'Edit',
      'target'        => 'section'
    }],
    'subsections'   => [
      $self->two_column([
        'Name'          => $user->display_name,
        'Email'         => $user->display_email,
        'Organisation'  => $user->display_organisation,
        'Country'       => $user->display_country,
        'Login via'     => @login_details > 1 ? sprintf('<div class="spaced">%s</div>', join('<br />', @login_details)) : $login_details[0]
      ])
    ]
  });
}

1;