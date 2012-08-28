package EnsEMBL::Users::Component::Account::OpenID::Buttons;

### Component for displaying a list of openid buttons for login/register page 
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self              = shift;
  my $object            = $self->object;
  my $hub               = $self->hub;
  my $then_param        = $self->get_then_param;
     $then_param        = $then_param ? { 'then' => $then_param } : {};

  my $openid_providers  = $object->openid_providers;
  my $trademarks        = [];
  my $trademark_owners  = [];
  my $content           = $self->wrapper_div({
    'class'               => 'login-openid',
    'children'            => [{
      'node_name'           => 'p',
      'inner_HTML'          => sprintf('If you already have an account with one of the following sites, click on the logo to login with it to %s.', $self->site_name)
    }]
  });
  my $openids_ul        = $content->append_child('ul');

  while (my ($key, $value) = splice @$openid_providers, 0, 2) {
    $openids_ul->append_child('li', {
      'children'  => [{
        'node_name' => 'a',
        'href'      => $hub->url({
          'species'   => '',
          'type'      => 'Account',
          'action'    => 'OpenID',
          'function'  => 'Request',
          'provider'  => $key,
          %$then_param
        }),
        'children'  => [{
          'node_name' => 'img',
          'src'       => sprintf('%s/i/openid_%s.png', $self->static_server, lc $key),
          'alt'       => $key,
          'title'     => "Login with $key",
          'width'     => '120',
          'height'    => '45'
        }],
        $value->{'url'} =~ /\[USERNAME\]/ ? ('class' => '_username') : (),
      }]
    });
    if ($value->{'trademark_owner'}) {
      push @$trademarks, $key;
      push @$trademark_owners, $value->{'trademark_owner'};
    }
  }

  if (my $count = @$trademarks) {
    $content->append_child('p', {'class' => 'trademark', 'inner_HTML' => sprintf('%s %s trademark%s of %s%s',
      $self->join_with_and(@$trademarks),
      $count == 1 ? 'is' : 'are',
      $count == 1 ? '' : 's',
      $self->join_with_and(@$trademark_owners),
      $count == 1 ? '.' : ' respectively.'
    )});
  }

  return $content->render;
}

1;