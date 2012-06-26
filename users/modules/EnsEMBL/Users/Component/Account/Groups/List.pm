package EnsEMBL::Users::Component::Account::Groups::List;

### Component to list all groups that are either open or restricted, and the current user is not a member of them
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;

  my $table       = $self->new_table([
    {'title' => 'Group Name',         'key' => 'name',    'width' => '20%'},
    {'title' => 'Number of members',  'key' => 'number',  'width' => '10%', 'class' => 'sort_numeric' },
    {'title' => 'Description',        'key' => 'desc',    'width' => '50%'},
    {'title' => 'Type',               'key' => 'type',    'width' => '10%'},
    {'title' => '',                   'key' => 'join',    'width' => '10%', 'class' => 'sort_html'    },
  ], [], {'data_table' => 'no_col_toggle', 'exportable' => 0, 'data_table_config' => {'iDisplayLength' => 25}});

  for (sort {$b->memberships_count('query' => ['status' => 'active', 'member_status' => 'active']) <=> $a->memberships_count('query' => ['status' => 'active', 'member_status' => 'active'])} @{$object->get_all_groups}) {
    my $membership = $user->get_membership_object($_);
    next if $_->type eq 'private' || $membership && ($membership->is_active || $membership->is_user_blocked);

    $table->add_row({
      'name'    => $self->html_encode($_->name),
      'number'  => $_->memberships_count('query' => ['status' => 'active', 'member_status' => 'active']),
      'desc'    => $self->html_encode($_->blurb),
      'type'    => ucfirst $_->type,
      'join'    => $membership && $membership->is_pending_request
      ? 'Request sent'
      : $self->js_link($membership && $membership->is_pending_invitation ? {
        'href'    => {'action' => 'Membership', 'function' => 'Accept', 'id' => $membership->group_member_id},
        'caption' => 'Accept invitation',
        'target'  => 'none',
        'inline'  => 1,
      } : {
        'href'    => {'action' => 'Group', 'function' => 'Join', 'id' => $_->group_id},
        'caption' => $_->type eq 'open' ? 'Join' : 'Send request',
        'target'  => 'none',
        'inline'  => 1,
      })
    });
  }

  return $self->js_section({'id' => 'list_all_groups', 'subsections' => [
    $table->render,
    $self->js_link({
      'href'    => {'action' => 'Groups', 'function' => ''},
      'caption' => 'Done',
      'target'  => 'page',
      'cancel'  => 'list_all_groups',
      'class'   => 'check'
    })
  ]});
}

1;