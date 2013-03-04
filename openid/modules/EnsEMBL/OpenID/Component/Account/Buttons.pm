package EnsEMBL::OpenID::Component::Account::Buttons;

### Component for displaying a list of openid buttons for login/register page 
### If the user is logged in, it displays a message to 'add login'
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

use constant JS_CLASS_OPENID_USERNAME => '_openid_username';

sub content {
  my $self              = shift;
  my $object            = $self->object;
  my $hub               = $self->hub;
  my $openid_providers  = $object->openid_providers;
  my $then_param        = $self->get_then_param;
  my $trademarks        = [];
  my $trademark_owners  = [];
  my $section           = {
    'js_panel'            => 'OpenIDButtons',
    'class'               => 'login-openid',
    'subsections'         => [ sprintf('<p>If you already have an account with %s, click on the logo to '. ($hub->user ? 'add it as an option to login to your %s account.' : 'login with it to %s.').'</p>',
      @$openid_providers == 2 ? $openid_providers->[0] : 'one of the following sites',
      $self->site_name
    ) ]
  };

  my $openids_ul        = $self->dom->create_element('ul');

  while (my ($key, $value) = splice @$openid_providers, 0, 2) {
    my (@link_class, $username_form);
    my %request_url     = ( qw(type Account action OpenID function Request) );
    my %request_params  = ( 'provider' => $key, $then_param ? ('then' => $then_param) : () );

    if ($value->{'url'} =~ /\[USERNAME\]/) {
      @link_class     = ('class' => $self->JS_CLASS_OPENID_USERNAME);
      $username_form  = $self->new_form({'method' => 'get', 'action' => \%request_url, 'skip_validation' => 1});
      $username_form->add_hidden({'name' => $_, 'value' => $request_params{$_}}) for keys %request_params;
      $username_form->add_field({
        'label'       => sprintf("$key username %s", $self->helptip("$key needs to know your username prior to us redirecting you to their login page.")),
        'inline'      => 1,
        'elements'    => [{
          'type'        => 'string',
          'name'        => 'username'
        }, {
          'type'        => 'submit',
          'value'       => 'Go'
        }]
      });
    }

    $openids_ul->append_child('li', {
      'children'      => [{
        'node_name'     => 'a',
        'href'          => $hub->url({%request_url, %request_params }),
        'children'      => [{
          'node_name'     => 'img',
          'src'           => sprintf('%s/i/openid_%s.png', $self->static_server, lc $key),
          'alt'           => $key,
          'width'         => '120',
          'height'        => '45'
        }],
        @link_class,
      }, $username_form ? {
        'node_name'     => 'div',
        'class'         => ['openid-username', 'tinted-box shadow-box', $self->JS_CLASS_OPENID_USERNAME],
        'children'      => [ $username_form ]
      } : ()]
    });
    if ($value->{'trademark_owner'}) {
      push @$trademarks, $key;
      push @$trademark_owners, $value->{'trademark_owner'};
    }
  }

  push @{$section->{'subsections'}}, $openids_ul->render;

  if (my $count = @$trademarks) {
    push @{$section->{'subsections'}}, $self->dom->create_element('p', {'class' => 'trademark', 'inner_HTML' => sprintf('%s %s trademark%s of %s%s',
      $self->join_with_and(@$trademarks),
      $count == 1 ? 'is' : 'are',
      $count == 1 ? '' : 's',
      $self->join_with_and(@$trademark_owners),
      $count == 1 ? '.' : ' respectively.'
    )})->render;
  }

  return $self->js_section($section);
}

1;
