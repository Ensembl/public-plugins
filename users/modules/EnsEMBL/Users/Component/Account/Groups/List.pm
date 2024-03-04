=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Component::Account::Groups::List;

### Component to list all groups that are either open or restricted, and the current user is not a member of them
### @author hr5

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;

  # create an 'easy to use' data structure
  my @groups;
  for (@{$object->fetch_groups({'query' => ['type' => [ 'open', 'restricted' ]]})}) {
    my $membership = $user->get_membership_object($_);
    unless ($membership && $membership->is_user_blocked) { # dont show the group that blocked this user
      push @groups, {
        'group'         => $_,
        'membership'    => $membership,
        'member_count'  => $_->memberships_count('query' => ['status' => 'active', 'member_status' => 'active'])
      };
    }
  }

  if (@groups) {

    my $table = $self->new_table([
      {'title' => 'Group Name',         'key' => 'name',    'width' => '20%'},
      {'title' => 'Number of members',  'key' => 'number',  'width' => '10%', 'class' => 'sort_numeric' },
      {'title' => 'Description',        'key' => 'desc',    'width' => '50%'},
      {'title' => 'Type',               'key' => 'type',    'width' => '10%'},
      {'title' => '',                   'key' => 'join',    'width' => '10%', 'class' => 'sort_html'    },
    ], [], {'class' => 'tint', 'data_table' => 'no_col_toggle', 'exportable' => 0, 'data_table_config' => {'iDisplayLength' => 25}});

    for (sort {$b->{'member_count'} <=> $a->{'member_count'}} @groups) {
      my $group       = $_->{'group'};
      my $membership  = $_->{'membership'};

      $table->add_row({
        'name'    => $self->html_encode($group->name),
        'number'  => $_->{'member_count'},
        'desc'    => $self->html_encode($group->blurb),
        'type'    => ucfirst $group->type,
        'join'    => $membership && $membership->is_active
        ? 'Already a member'
        : (
          $membership && $membership->is_pending_request
          ? 'Request sent'
          : $self->js_link($membership && $membership->is_pending_invitation ? {
            'href'    => {'action' => 'Membership', 'function' => 'Accept', 'id' => $membership->group_member_id, 'csrf_safe' => 1},
            'caption' => 'Accept invitation'
          } : {
            'href'    => {'action' => 'Group', 'function' => 'Join', 'id' => $group->group_id, 'csrf_safe' => 1},
            'caption' => $group->type eq 'open' ? 'Join' : 'Send request'
          })
        )
      });
    }

    return $self->js_section({'subsections' => [
      $table->render,
      $self->js_link({
        'href'    => {'action' => 'Preferences', 'function' => ''},
        'caption' => 'Done',
        'class'   => 'check',
        'button'  => 1
      })
    ]});

  } else {

    return $self->js_section({
      'heading'     => 'No group found to join ',
      'subsections' => [ sprintf(q(<p>No public user group exists for %s that you can join. If you want to create a new group, please %s.</p>),
        $self->site_name,
        $self->js_link({'href' => {'action' => 'Groups', 'function' => 'Add'}, 'caption' => 'click here'})
      )]
    });
  }
}

1;