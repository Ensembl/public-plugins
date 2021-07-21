=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Component::Account::Groups::ViewAll;

### Page for a logged in user to view all of his groups
### @author hr5

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $user        = $hub->user->rose_object;
  my $memberships = $user->find_memberships('with_objects' => 'group', 'query' => ['or' => ['level' => 'administrator', 'and' => ['group.status' => 'active', '!group.type' => 'hidden']]]); # show inactive groups to admins only
  my $section     = {
    'heading'       => 'Groups',
    'heading_links' => [{
      'href'          => {qw(action Groups function Add)},
      'title'         => 'Create new group',
      'sprite'        => 'user-group-add-icon',
    }, {
      'href'          => {qw(action Groups function List)},
      'title'         => 'Join an existing group',
      'sprite'        => 'user-group-join-icon',
    }],
    'subsections'   => [ '<p>You are not a member of any group.</p>' ] # will get overwritten if groups found
  };

  if (@$memberships) {
    my $table = $self->new_table([
      {'title' => 'Group Name',         'key' => 'name',    'width' => '30%'},
      {'title' => 'Description',        'key' => 'desc',    'width' => '50%'},
      {'title' => 'Number of members',  'key' => 'number',  'width' => '10%', 'class' => 'sort_numeric' },
      {'title' => '',                   'key' => 'edit',    'width' => '10%', 'class' => 'sort_html'    },
    ], [], {'class' => 'tint', 'data_table' => 'no_col_toggle', 'exportable' => 0});

    for (sort {uc $a->group->name cmp uc $b->group->name} @$memberships) {
      my $is_pending_request  = $_->is_pending_request;
      next unless $_->is_active || $is_pending_request;
      my $group               = $_->group;
      my $is_inactive_group   = $group->status eq 'inactive';
      $table->add_row({
        'name'    => sprintf('%s%s', $self->html_encode($group->name), $is_inactive_group ? ' <i>(inactive)</i>' : ''),
        'number'  => $group->memberships_count('query' => ['status' => 'active', 'member_status' => 'active']),
        'desc'    => $self->html_encode($group->blurb),
        'edit'    => $self->js_link({
          $is_pending_request ? (
            'href'    => {'action' => 'Membership', 'function' => 'Unjoin', 'id' => $_->group_member_id, 'csrf_safe' => 1},
            'caption' => 'Delete request'
          ) : (
            'href'    => {'action' => 'Groups', 'function' => 'View', 'id' => $_->group_id},
            'caption' => $_->level eq 'member' ? 'View' : 'Moderate'
          )
        }),
        $is_inactive_group ? ('options' => {'class' => 'inactive'}) : ()
      });
    }

    $section->{'subsections'} = [ $table->render ] if $table->has_rows;
  }

  return $self->js_section($section);
}

1;