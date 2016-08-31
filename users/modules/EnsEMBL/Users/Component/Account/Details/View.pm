=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Users::Component::Account::Details::View;

### Page for a logged in user to view his detals
### @author hr5

use strict;
use warnings;

use HTML::Entities qw(encode_entities);

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $user            = $hub->user;
  my $r_user          = $user->rose_object;
  my $openid_enabled  = $hub->species_defs->ENSEMBL_OPENID_ENABLED;
  my $ldap_enabled    = $hub->species_defs->ENSEMBL_LDAP_ENABLED;
  my $logins          = $r_user->find_logins($openid_enabled && $ldap_enabled ? () : ('query' => ['type' => [ 'local', $openid_enabled ? 'openid' : (), $ldap_enabled ? 'ldap' : () ]]));
  my $site_name       = $self->site_name;

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
      $login_detail = sprintf $login_detail, $login_provider, $object->login_has_trusted_provider($_) ? $_->email : $_->identity;
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

  if ($openid_enabled || $ldap_enabled) {
    push @login_details, $self->js_link({
      'caption' => 'Add login',
      'helptip' => sprintf('Click to add another login option via %s', $self->join_with_or(grep {!ref $_} @{$self->object->openid_providers})),
      'href'    => {qw(action Details function AddLogin)}
    });
  }

  return $self->js_section({
    'heading'       => 'User Details',
    'heading_links' => [{
      'sprite'        => 'edit_icon',
      'href'          => {qw(action Details function Edit)},
      'title'         => 'Edit'
    }],
    'subsections'   => [
      $self->two_column([
        'Name'          => encode_entities($user->name),
        'Email'         => encode_entities($user->email),
        'Organisation'  => encode_entities($user->organisation),
        'Country'       => encode_entities($self->hub->species_defs->COUNTRY_CODES->{$user->country || ''} || ''),
        'Login via'     => @login_details > 1 ? sprintf('<div class="spaced">%s</div>', join('<br />', @login_details)) : $login_details[0]
      ])
    ]
  });
}

1;